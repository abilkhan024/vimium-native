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
  private var traversalTask: Task<Void, Never>?
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
    let timeline = BenchTimeline("hints", start: BenchUtils.tapTime)
    timeline.mark("tap -> main dispatch")
    BenchUtils.resetTotals()

    state.search = ""
    InputSourceUtils.selectAbc()
    timeline.mark("selectAbc")
    hintsWindow.front().call()
    timeline.mark("window front")
    hintsWindow.hideCursor().call()
    timeline.mark("hideCursor")
    state.loading = true
    appListener = AppListener(onEvent: self.onTyping)
    AppEventManager.add(self.appListener!)
    timeline.mark("loading state + add listener")
    BenchUtils.afterNextCommit { timeline.mark("first commit (loading)") }

    traversalTask = Task { [weak self] in
      guard let self else { return }
      timeline.mark("task start")
      let hints = await self.getFrontMostClickableHints(timeline)
      guard !Task.isCancelled else { return }

      var visit = Set<Int>()
      self.hints = hints.filter({ el in
        guard let point = el.point else { return false }
        if visit.contains(point.hashValue) { return false }
        visit.insert(point.hashValue)
        return true
      })
      timeline.mark("dedupe (\(hints.count) -> \(self.hints.count) hints)")
      self.state.hints = self.hints
      let config_val = 2
      self.state.texts = HintUtils.getLabels(
        from: max(
          self.state.hints.count,
          AppOptions.shared
            .hintChars.count * config_val + 1))
      timeline.mark("labels")
      self.state.loading = false
      timeline.mark("state set")
      BenchUtils.afterNextCommit {
        timeline.mark("hints commit (SwiftUI body + layout + CA commit)")
        BenchUtils.printTotals("hints")
      }
    }
  }

  private func getFrontMostClickableHints(_ timeline: BenchTimeline) async -> [AxElement] {
    guard let app = NSWorkspace.shared.frontmostApplication else { return [] }
    let pid = app.processIdentifier
    let appEl = AXUIElementCreateApplication(pid)

    AXUIElementSetAttributeValue(appEl, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)
    timeline.mark("set AXEnhancedUserInterface")
    var winRef: CFTypeRef?
    let winResult = AXUIElementCopyAttributeValue(
      appEl, kAXMainWindowAttribute as CFString, &winRef)

    timeline.mark("copy main window")
    guard winResult == .success, let mainWindow = winRef as! AXUIElement? else { return [] }

    let result = await AxElement(mainWindow).findVisible()
    timeline.mark("traversal (findVisible)")
    return result
  }

  private func onClose() {
    traversalTask?.cancel()
    traversalTask = nil
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
      self.state.loading = false
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
    let timeline = BenchTimeline("key", start: BenchUtils.tapTime)
    timeline.mark("tap -> main dispatch")
    BenchUtils.resetTotals()
    defer {
      timeline.mark("handled")
      BenchUtils.afterNextCommit {
        timeline.mark("commit (SwiftUI body + layout + CA commit)")
        BenchUtils.printTotals("key")
      }
    }
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
        if AppOptions.shared.axLinkClick && self.hints[idx].role == .Link {
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
