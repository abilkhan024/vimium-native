import CoreGraphics
@preconcurrency import SwiftUI

@MainActor
class FzFindListener: Listener {
  private let hintsWindow = FzFindWindowManager.get(.hints)
  private var appListener: AppListener?
  private let state = FzFindState.shared
  private var hints: [AxElement] = []
  private let hintableRoles: Set<String> = [
    "AXButton",
    "AXComboBox",
    "AXCheckBox",
    "AXRadioButton",
    "AXLink",
    "AXImage",
    "AXCell",
    "AXMenuBarItem",
    "AXMenuItem",
    "AXMenuBar",
    "AXPopUpButton",
    "AXTextField",
    "AXSlider",
    "AXTabGroup",
    "AXTabButton",
    "AXTable",
    "AXOutline",
    "AXRow",
    "AXColumn",
    "AXScrollBar",
    "AXSwitch",
    "AXToolbar",
    "AXDisclosureTriangle",
  ]
  private let ignoredActions = [
    "AXShowMenu",
    "AXScrollToVisible",
    "AXShowDefaultUI",
    "AXShowAlternateUI",
  ]

  init() {
    hintsWindow.render(AnyView(FzFindHintsView())).call()
  }

  // NOTE: May be doing, AXUIElementCopyElementAtPosition concurently, and
  // getting all the children of those or something?
  // ------
  // Limitations:
  // 1. Must get system from top right half using func above
  // 2. Need some validation for tableplus
  // 3. Doesn't show handles for activity cells in monitor
  private func getVisibleEls() -> [AxElement] {
    let wg = DispatchGroup()
    let hintText = AppOptions.shared.hintText
    let roleBased = AppOptions.shared.selection == .role

    guard let app = NSWorkspace.shared.frontmostApplication, let screen = NSScreen.main else {
      return []
    }
    let frame = AxElement.Frame(height: screen.frame.height, width: screen.frame.width)
    let flags = AxElement.Flags(hintText: hintText, roleBased: roleBased)

    let pid = app.processIdentifier
    let appEl = AXUIElementCreateApplication(pid)

    var winRef: CFTypeRef?
    let winResult = AXUIElementCopyAttributeValue(
      appEl, kAXMainWindowAttribute as CFString, &winRef)

    guard winResult == .success, let mainWindow = winRef as! AXUIElement? else { return [] }

    nonisolated(unsafe) var result: [AxElement] = []
    let queue = DispatchQueue(label: "result-append-queue", attributes: .concurrent)

    @Sendable
    func dfs(_ el: AxElement, _ parents: [AxElement]) {
      let visible = el.getIsVisible(frame, parents)
      if visible == false {
        return
      }
      var childrenRef: CFTypeRef?

      let childParents = parents + [el]
      let childResult = AXUIElementCopyAttributeValue(
        el.raw, kAXChildrenAttribute as CFString, &childrenRef)
      if childResult == .success, let children = childrenRef as? [AXUIElement] {
        for _ in children {
          wg.enter()
        }
        DispatchQueue.global(qos: .userInteractive).async {
          DispatchQueue.concurrentPerform(iterations: children.count) { i in
            dfs(AxElement(children[i]), childParents)
            wg.leave()
          }
        }
      }

      if el.getIsHintable(flags) {
        wg.enter()
        queue.async(flags: .barrier) {
          wg.leave()
          result.append(el)
        }
      }
    }

    wg.enter()
    DispatchQueue.global(qos: .userInteractive).async {
      dfs(AxElement(mainWindow), [])
      wg.leave()
    }
    wg.wait()

    return result
  }

  func match(_ event: CGEvent) -> Bool {
    let flags = event.flags
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    return flags.contains(.maskCommand) && flags.contains(.maskShift)
      && keyCode == Keys.dot.rawValue
  }

  private func getChildren(_ el: AXUIElement) -> [AXUIElement] {
    var childrenRef: CFTypeRef?

    let childResult = AXUIElementCopyAttributeValue(
      el, kAXChildrenAttribute as CFString, &childrenRef)
    if childResult == .success, let children = childrenRef as? [AXUIElement] {
      return children
    }
    return []
  }

  func removeDuplicates(from els: [AxElement], within radius: Double) -> [AxElement] {
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

  func callback(_ event: CGEvent) {
    if self.appListener != nil {
      return
    }
    state.search = ""
    self.hintsWindow.front().call()
    state.loading = true
    self.appListener = AppListener(onEvent: self.onTyping)
    AppEventManager.add(self.appListener!)

    DispatchQueue.main.async {
      let start = DispatchTime.now().uptimeNanoseconds
      let hints = self.removeDuplicates(from: self.getVisibleEls(), within: 8)
      if AppOptions.shared.debugPerf {
        print("Generated in \(DispatchTime.now().uptimeNanoseconds - start) for \(hints.count)")
      }
      self.hints = hints
      self.state.hints = self.hints
      self.state.texts = HintUtils.getLabels(from: self.state.hints.count)
      self.state.loading = false
    }
  }

  private func onClose() {
    hintsWindow.hide().call()
    DispatchQueue.main.async {
      if let listener = self.appListener {
        AppEventManager.remove(listener)
        self.appListener = nil
      }
      self.state.hints = []
      self.state.search = ""
    }
  }

  private func onTyping(_ event: CGEvent) {
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    switch keyCode {
    case Keys.slash.rawValue:
      return  // FZF mode incoming
    case Keys.esc.rawValue:
      return onClose()
    case Keys.quote.rawValue:
      self.state.zIndexInverted = !self.state.zIndexInverted
    default:
      guard let char = EventUtils.getEventChar(from: event) else { return }
      state.search.append(char)
      if self.state.texts.firstIndex(where: { str in str.starts(with: state.search) }) == nil {
        return onClose()
      }

      if let idx = self.state.texts.firstIndex(of: state.search), idx < self.hints.count,
        let point = self.hints[idx].point
      {
        EventUtils.leftClick(point, event.flags)
        onClose()
      }
    }
  }
}
