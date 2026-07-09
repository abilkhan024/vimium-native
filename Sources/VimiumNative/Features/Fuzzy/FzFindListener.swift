import CoreGraphics
@preconcurrency import SwiftUI

// TODO: Add feature that selects/copies text for text elements
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
      var visit = Set<Int>()
      let hints = self.getFrontMostClickableHints()
      self.hints = hints.filter({ el in
        guard let point = el.point else { return false }
        if visit.contains(point.hashValue) { return false }
        visit.insert(point.hashValue)
        return true
      })
      self.state.hints = self.hints
      self.state.texts = HintUtils.getLabels(from: self.state.hints.count)
      self.state.loading = false
    }
  }

  private func getFrontMostClickableHints() -> [AxElement] {
    guard let app = NSWorkspace.shared.frontmostApplication else { return [] }
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
        if self.hints[idx].canPress() && AppOptions.shared.axClick {
          self.hints[idx].click()
        } else {
          EventUtils.leftClick(point, event.flags)
        }
        onClose()
      }
      return
    }

    let _ = bestAction(event)
  }
}
