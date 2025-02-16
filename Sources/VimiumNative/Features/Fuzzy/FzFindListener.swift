import CoreGraphics
@preconcurrency import SwiftUI

@MainActor
class FzFindListener: Listener {
  private let hintsWindow = FzFindWindowManager.get(.hints)
  private var appListener: AppListener?
  private let state = FzFindState.shared
  private var hints: [AxElement] = []
  private var visibleEls: [HintElement] = []
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

  // 1. Must get system from top right half using el at point?
  // 2. Need some validation for tableplus
  // 3. Doesn't show handles for activity cells in monitor
  private func getVisibleEls() -> [AXUIElement] {
    let wg = DispatchGroup()
    let queue = DispatchQueue(label: "thread-safe-obj", attributes: .concurrent)
    let hintText = AppOptions.shared.hintText
    let roleBased = AppOptions.shared.selection == .role

    guard let app = NSWorkspace.shared.frontmostApplication else {
      return []
    }
    nonisolated(unsafe) var result: [AXUIElement] = []

    @Sendable
    func isHintable(_ el: AXUIElement) -> Bool {
      guard let role = AxElementUtils.getAttributeString(el, kAXRoleAttribute) else {
        return false
      }
      if hintText && role == "AXStaticText" {
        return true
      }

      if roleBased {
        return hintableRoles.contains(role)
      }

      if role == "AXImage" || role == "AXCell" {
        return true
      }

      if role == "AXWindow" || role == "AXScrollArea" {
        return false
      }

      var names: CFArray?
      let error = AXUIElementCopyActionNames(el, &names)

      if error != .success {
        return false
      }

      let actions = names! as [AnyObject] as! [String]
      var count = 0
      for ignored in ignoredActions {
        for action in actions {
          if action == ignored {
            count += 1
          }
        }
      }

      let hasActions = actions.count > count

      return hasActions
    }

    @Sendable
    func dfs(_ el: AXUIElement) {
      let visible = AxElementUtils.isVisible(el)
      if visible == false {
        return
      }

      if isHintable(el) {
        wg.enter()
        queue.async(flags: .barrier) {
          wg.leave()
          result.append(el)
        }
      }

      var childrenRef: CFTypeRef?

      let childResult = AXUIElementCopyAttributeValue(
        el, kAXChildrenAttribute as CFString, &childrenRef)
      if childResult == .success, let children = childrenRef as? [AXUIElement] {
        for _ in children {
          wg.enter()
        }
        DispatchQueue.global(qos: .userInteractive).async {
          DispatchQueue.concurrentPerform(iterations: children.count) { i in
            dfs(children[i])
            wg.leave()
          }
        }
      }
    }

    let pid = app.processIdentifier
    let appEl = AXUIElementCreateApplication(pid)
    var wins: CFTypeRef?
    let winResult = AXUIElementCopyAttributeValue(appEl, kAXWindowsAttribute as CFString, &wins)
    guard winResult == .success, let windows = wins as? [AXUIElement] else {
      return []
    }
    for _ in windows {
      wg.enter()
    }
    DispatchQueue.global(qos: .userInteractive).async {
      DispatchQueue.concurrentPerform(iterations: windows.count) { i in
        dfs(windows[i])
        wg.leave()
      }
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
      let els = self.getVisibleEls()
      if AppOptions.shared.debugPerf {
        print("Generated in \(DispatchTime.now().uptimeNanoseconds - start) for \(els.count)")
      }
      var hints = els.map { e in AxElement(e) }
      hints = self.removeDuplicates(from: hints, within: 8)
      self.hints = hints
      self.state.hints = self.hints
      self.state.texts = HintUtils.getLabels(from: self.state.hints.count)
      self.state.loading = false
      if AppOptions.shared.debugPerf {
        print("Generated in \(DispatchTime.now().uptimeNanoseconds - start) for \(els.count)")
      }
    }
  }

  private func axuiToHint(_ count: Int, _ idx: Int, _ el: AXUIElement) -> HintElement {
    let seq = HintUtils.getLabels(from: count)
    let id = seq[idx]
    var hint = HintElement(id: id, axui: el, content: AxElementUtils.toString(el))
    if let point = AxElementUtils.getPoint(el),
      let size = AxElementUtils.getSize(el)
    {
      hint.position = CGPointMake(point.x + size.width / 2, point.y + size.height / 2)
    }

    return hint
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
    case Keys.esc.rawValue:
      return onClose()
    case Keys.quote.rawValue:
      self.state.zIndexInverted = !self.state.zIndexInverted
    default:
      guard let char = SystemUtils.getChar(from: event) else { return }
      state.search.append(char)
      if self.state.texts.firstIndex(where: { str in str.starts(with: state.search) }) == nil {
        return onClose()
      }

      if let idx = self.state.texts.firstIndex(of: state.search), idx < self.hints.count,
        let point = self.hints[idx].point
      {
        SystemUtils.click(point, event.flags)
        onClose()
      }
    }
  }
}
