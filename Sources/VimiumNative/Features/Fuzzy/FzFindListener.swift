import CoreGraphics
@preconcurrency import SwiftUI

@Sendable
private func dfs(
  _ el: AxElement, _ parents: [AxElement], _ wg: DispatchGroup,
  _ execQueue: DispatchQueue, _ flags: AxElement.Flags,
  _ onFound: @escaping @Sendable (_: AxElement) -> Void
) {
  if parents.contains(where: { parent in parent.raw == el.raw }) {
    return
  }
  let visible = el.getIsVisible(flags)
  if visible != true {
    return
  }
  var childrenRef: CFTypeRef?

  let childParents = parents + [el]
  let childResult = AXUIElementCopyAttributeValue(
    el.raw, kAXChildrenAttribute as CFString, &childrenRef)
  if childResult == .success, let children = childrenRef as? [AXUIElement] {
    for child in children {
      wg.enter()
      execQueue.async {
        dfs(AxElement(child, parents: childParents), childParents, wg, execQueue, flags, onFound)
        wg.leave()
      }
    }
  }

  if el.getIsHintable(flags) {
    onFound(el)
  }
}

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
      let start = DispatchTime.now().uptimeNanoseconds
      let hints = self.removeDuplicates(from: self.getVisibleEls(), within: 16)
      if AppOptions.shared.debugPerf {
        print("Generated in \(DispatchTime.now().uptimeNanoseconds - start) for \(hints.count)")
      }
      self.hints = hints
      self.state.hints = self.hints
      self.state.texts = HintUtils.getLabels(from: self.state.hints.count)
      self.state.loading = false
    }
  }

  private func getAxFlags() -> AxElement.Flags {
    return AxElement.Flags(
      traverseHidden: AppOptions.shared.traverseHidden,
      hintText: AppOptions.shared.hintText,
      roleBased: AppOptions.shared.selection == .role
    )

  }

  private func pollSysMenu() {
    guard let screen = NSScreen.main else { return }
    let flags = getAxFlags()
    nonisolated(unsafe) var result: [AxElement] = []
    let queue = DispatchQueue(label: "result-append-queue", attributes: .concurrent)

    let onFound: @Sendable (_: AxElement) -> Void = { e in
      queue.async(flags: .barrier) { result.append(e) }
    }

    let maxX = screen.frame.maxX
    let wg = DispatchGroup()

    var min = maxX / 2
    let max = maxX
    let step = 11.0
    let menuBarY: Float = 11.0

    var positionsToCheck: [Float] = []
    while min + step < max {
      positionsToCheck.append(Float(min + step / 2))
      min += step
    }

    let sys = AXUIElementCreateSystemWide()

    for pos in positionsToCheck {
      wg.enter()
      execQueue.async {
        var el: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(sys, pos, menuBarY, &el)
        if result == .success, let axui = el as AXUIElement? {
          dfs(AxElement(axui), [], wg, self.execQueue, flags, onFound)
        }
        wg.leave()
      }
    }
    wg.wait()
    self.systemMenuItems = result
  }

  private func getVisibleEls() -> [AxElement] {
    let wg = DispatchGroup()

    guard let app = NSWorkspace.shared.frontmostApplication else {
      print("Failed to get the app")
      return []
    }
    let flags = getAxFlags()

    let pid = app.processIdentifier
    let appEl = AXUIElementCreateApplication(pid)

    AXUIElementSetAttributeValue(appEl, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)
    var winRef: CFTypeRef?
    let winResult = AXUIElementCopyAttributeValue(
      appEl, kAXMainWindowAttribute as CFString, &winRef)

    guard winResult == .success, let mainWindow = winRef as! AXUIElement? else { return [] }

    nonisolated(unsafe) var result = systemMenuItems
    let queue = DispatchQueue(label: "result-append-queue", attributes: .concurrent)
    let onFound: @Sendable (_: AxElement) -> Void = { e in
      queue.async(flags: .barrier) { result.append(e) }
    }

    // wg.enter()
    // execQueue.async {
    //   var menuBar: AnyObject?
    //
    //   let result = AXUIElementCopyAttributeValue(
    //     appEl, kAXMenuBarAttribute as CFString, &menuBar)
    //
    //   if result == .success, let menuBarElement = menuBar as! AXUIElement? {
    //     dfs(AxElement(menuBarElement), [], wg, self.execQueue, flags, onFound)
    //   }
    //   wg.leave()
    // }

    return AxElement(mainWindow).findVisible()
    // .sorted(by: { a, b in
    //   guard let boundA = a.bound, let boundB = b.bound else { return false }
    //   let xa = round(boundA.origin.x)
    //   let xb = round(boundB.origin.x)
    //   let ya = round(boundA.origin.y)
    //   let yb = round(boundB.origin.y)
    //   if ya == yb {
    //     return xa < xb
    //   }
    //   return ya < yb
    // })

    // wg.enter()
    // execQueue.async {
    //   wg.leave()
    // }
    // wg.wait()

    // return result.sorted(by: { a, b in a.getSortableKey() < b.getSortableKey() })
  }

  private func removeDuplicates(from els: [AxElement], within radius: Double) -> [AxElement] {
    var uniqueEls: [AxElement] = []

    for el in els {
      guard let point = el.point else { continue }
      var isDuplicate = false
      for unique in uniqueEls {
        let existingPoint = unique.point
        let dx = point.x - existingPoint!.x
        let dy = point.y - existingPoint!.y
        let distanceSquared = dx * dx + dy * dy
        if distanceSquared <= radius * radius {
          isDuplicate = true
          break
        }
      }
      if !isDuplicate {
        uniqueEls.append(el)
      }
    }

    return uniqueEls
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
        EventUtils.leftClick(point, event.flags)
        onClose()
      }
      return
    }

    let _ = bestAction(event)
  }
}
