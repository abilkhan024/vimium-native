import CoreGraphics
@preconcurrency import SwiftUI

@MainActor
class FzFindListener: Listener {
  private let hintsWindow = FzFindWindowManager.get(.hints)
  private var appListener: AppListener?
  private let state = FzFindState.shared
  private var hints: [AxElement] = []
  private var tmp: WindowBuilder?
  private let execQueue = DispatchQueue.global(qos: .userInteractive)
  private var systemMenuItems: [AxElement] = []
  private let mappings = AppOptions.shared.keyMappings

  init() {
    hintsWindow.render(AnyView(FzFindHintsView())).call()
    if AppOptions.shared.systemMenuPoll != 0 {
      Timer.scheduledTimer(
        withTimeInterval: Double(AppOptions.shared.systemMenuPoll), repeats: true,
        block: { _ in
          DispatchQueue.main.async {
            self.pollSysMenu()
          }
        })
      DispatchQueue.main.async {
        self.pollSysMenu()
      }
    }
  }

  func abort() {
    onClose()
  }

  func matches(_ event: CGEvent) -> Bool {
    return mappings.showHints.matches(event: event)
  }

  func callback(_ event: CGEvent) {
    if self.appListener != nil {
      return
    }
    state.search = ""
    InputSourceUtils.selectAbc()
    hintsWindow.front().hideCursor().call()
    state.loading = true
    appListener = AppListener(onEvent: self.onTyping)
    AppEventManager.add(self.appListener!)

    DispatchQueue.main.async {
      let hints = self.getVisibleEls()
      self.hints = hints
      self.state.hints = self.hints
      self.state.texts = HintUtils.getLabels(from: self.state.hints.count)
      // TODO REMOVE LATER WHEN NEW FINDER LOGIC WORKS CORRECTLY
      // var ids: [Int] = []
      // for i in self.state.texts.indices {
      //   let text = self.state.texts[i]
      //   if text.starts(with: "khi") {
      //     ids.append(i)
      //   }
      // }
      // for id in ids {
      //   if id < self.state.hints.count {
      //     let el = self.state.hints[id]
      //     print("el:", el.debug(), el.bound)
      //   }
      // }
      self.state.loading = false
    }
  }

  private func pollSysMenu() {
    // guard let screen = NSScreen.main else { return }
    // TODO REWRITE as iterative
    // nonisolated(unsafe) var result: [AxElement] = []
    // let queue = DispatchQueue(label: "result-append-queue", attributes: .concurrent)
    //
    // let onFound: @Sendable (_: AxElement) -> Void = { e in
    //   queue.async(flags: .barrier) { result.append(e) }
    // }
    //
    // let maxX = screen.frame.maxX
    // let wg = DispatchGroup()
    //
    // var min = maxX / 2
    // let max = maxX
    // let step = 11.0
    // let menuBarY: Float = 11.0
    //
    // var positionsToCheck: [Float] = []
    // while min + step < max {
    //   positionsToCheck.append(Float(min + step / 2))
    //   min += step
    // }
    //
    // let sys = AXUIElementCreateSystemWide()
    //
    // for pos in positionsToCheck {
    //   wg.enter()
    //   execQueue.async {
    //     var el: AXUIElement?
    //     let result = AXUIElementCopyElementAtPosition(sys, pos, menuBarY, &el)
    //     if result == .success, let axui = el as AXUIElement? {
    //       dfs(AxElement(axui), [], wg, self.execQueue, flags, onFound)
    //     }
    //     wg.leave()
    //   }
    // }
    // wg.wait()
    self.systemMenuItems = []
  }

  private func getVisibleEls() -> [AxElement] {
    guard let app = NSWorkspace.shared.frontmostApplication else {
      print("Failed to get the app")
      return []
    }

    let pid = app.processIdentifier
    let appEl = AXUIElementCreateApplication(pid)

    AXUIElementSetAttributeValue(appEl, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)
    var winRef: CFTypeRef?
    let winResult = AXUIElementCopyAttributeValue(
      appEl, kAXMainWindowAttribute as CFString, &winRef)

    guard winResult == .success, let mainWindow = winRef as! AXUIElement? else { return [] }

    return AxElement(mainWindow).findVisible()
  }

  private func onClose() {
    InputSourceUtils.restoreCurrent()
    hintsWindow.hide().call()
    DispatchQueue.main.async {
      if let listener = self.appListener {
        AppEventManager.remove(listener)
        self.appListener = nil
      }
      self.state.fzfSelectedIdx = -1
      self.state.fzfMode = false
      self.state.hints = []
      self.state.search = ""
    }
  }

  private func focusOccurence(prev: Bool = false, next: Bool = false) {
    precondition((prev || next) && !(prev && next), "ERROR: Either prev or next can be true")

    let search = self.state.search.lowercased().replacingOccurrences(of: " ", with: "")
    let idxs = self.state.hints.indices.filter { i in
      self.state.hints[i].getSearchTerm().contains(search)
    }
    if idxs.isEmpty {
      return
    }
    guard let curIdx = idxs.firstIndex(of: self.state.fzfSelectedIdx) else {
      return print("WARNING: That should never happen")
    }
    var nextIdx = prev ? max(curIdx - 1, 0) : min(curIdx + 1, idxs.count - 1)
    if nextIdx == curIdx && prev {
      nextIdx = idxs.count - 1
    } else if nextIdx == curIdx && next {
      nextIdx = 0
    }
    self.state.fzfSelectedIdx = idxs[nextIdx]
  }

  private lazy var keyToPrimeAction: [KeyMapping: (_: CGEvent) -> Bool] = [
    mappings.enterSearchMode: { _ in
      self.state.fzfMode = true
      InputSourceUtils.restoreCurrent()
      self.state.search = ""
      return false
    },
    mappings.close: { _ in
      self.onClose()
      return false
    },
    mappings.toggleZIndex: { _ in
      self.state.zIndexInverted.toggle()
      return false
    },
    mappings.nextSearchOccurence: { _ in
      guard self.state.fzfMode else { return true }
      self.focusOccurence(next: true)
      return false
    },
    mappings.prevSearchOccurence: { _ in
      guard self.state.fzfMode else { return true }
      self.focusOccurence(prev: true)
      return false
    },
    mappings.selectOccurence: { event in
      guard self.state.fzfMode else { return true }
      if self.state.fzfSelectedIdx != -1, let point = self.hints[self.state.fzfSelectedIdx].point {
        EventUtils.leftClick(point, event.flags)
        self.onClose()
      }
      return false
    },
    mappings.dropLastSearchChar: { _ in
      guard self.state.fzfMode else { return true }
      if !self.state.search.isEmpty {
        self.state.search.removeLast()
      }
      return false
    },

  ]

  // NOTE: Assuming that there will be no usage of conflicting keymappings
  private func onTyping(_ event: CGEvent) {
    guard
      let bestActionKey = keyToPrimeAction.keys.max(by: { a, b in
        a.getScore(event: event) < b.getScore(event: event)
      }),
      bestActionKey.matches(event: event),
      let bestAction = keyToPrimeAction[bestActionKey]
    else {
      guard let char = EventUtils.getEventChar(from: event) else { return }
      state.search.append(char)
      if self.state.fzfMode {
        let search = self.state.search.lowercased().replacingOccurrences(of: " ", with: "")
        if self.state.fzfSelectedIdx != -1
          && self.state.hints[self.state.fzfSelectedIdx].getSearchTerm().contains(search)
        {
          return
        }
        if let defaultIdx = self.state.hints.firstIndex(where: { e in
          e.getSearchTerm().contains(search)
        }) {
          self.state.fzfSelectedIdx = defaultIdx
        } else {
          self.state.fzfSelectedIdx = -1
        }
        return
      }
      if self.state.texts.firstIndex(where: { str in str.starts(with: state.search) }) == nil {
        return onClose()
      }

      if let idx = self.state.texts.firstIndex(of: state.search), idx < self.hints.count,
        let point = self.hints[idx].point
      {
        EventUtils.move(point)
        // faster-more-precise-dfs tbd may be add focus regions for each element or prevent overlapping elements
        // if event.flags.contains(Modifier.command.cgEventFlag) {
        //   self.hints[idx].click()
        // }

        EventUtils.leftClick(point, event.flags)
        onClose()
      }
      return
    }

    let _ = bestAction(event)
  }
}
