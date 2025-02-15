import CoreGraphics
import SwiftUI

@MainActor
class FzFindListener: Listener {
  private let hintsWindow = FzFindWindowManager.get(.hints)
  private var appListener: AppListener?
  private let state = FzFindState.shared
  private var hints: [AxElement] = []
  private var visibleEls: [HintElement] = []
  private let ignoredActions = [
    "AXShowMenu",
    "AXScrollToVisible",
    "AXShowDefaultUI",
    "AXShowAlternateUI",
  ]

  init() {
    hintsWindow.render(AnyView(FzFindHintsView())).call()
  }

  func match(_ event: CGEvent) -> Bool {
    let flags = event.flags
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    return flags.contains(.maskCommand) && flags.contains(.maskShift)
      && keyCode == Keys.dot.rawValue
  }

  func isHintable(_ el: AXUIElement) -> Bool {
    guard let role = AxElementUtils.getAttributeString(el, kAXRoleAttribute) else {
      return false
    }
    if AppOptions.shared.hintText && role == "AXStaticText" {
      return true
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

  func getVisibleEls() -> [AXUIElement] {
    // 1. Must get system from top right half using el at point?
    // 2. Need some validation for tableplus
    // 3. Doesn't show handles for activity cells in monitor

    let app = NSWorkspace.shared.frontmostApplication!
    let pid = app.processIdentifier

    let appEl = AXUIElementCreateApplication(pid)
    var els: [AXUIElement] = []
    var wins: CFTypeRef?
    let winResult = AXUIElementCopyAttributeValue(appEl, kAXWindowsAttribute as CFString, &wins)

    guard winResult == .success, let windows = wins as? [AXUIElement] else {
      return []
    }

    var stack: [AXUIElement] = []
    for el in windows {
      stack.append(el)
      if AxElementUtils.getAttributeString(el, kAXRoleAttribute) == "AXWindow" {
        break
      }
    }

    var menubarRef: AnyObject?
    let menuResult = AXUIElementCopyAttributeValue(
      appEl, kAXMenuBarAttribute as CFString, &menubarRef)

    if menuResult == .success, let menu = menubarRef as! AXUIElement? {
      stack.append(menu)
    }

    while !stack.isEmpty {
      let sub = stack.popLast()!
      let visible = AxElementUtils.isVisible(sub)
      let subIsHintable = isHintable(sub)

      if visible != false {
        var childrenRef: CFTypeRef?

        let childResult = AXUIElementCopyAttributeValue(
          sub, kAXChildrenAttribute as CFString, &childrenRef)
        if childResult == .success, let children = childrenRef as? [AXUIElement] {
          stack.append(contentsOf: children)
        }
      }

      if subIsHintable && visible == true {
        els.append(sub)
      }
    }

    return els
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
      let els = self.getVisibleEls()
      var hints = els.map { e in AxElement(e) }
      hints = self.removeDuplicates(from: hints, within: 8)
      self.hints = hints
      self.state.hints = self.hints
      self.state.texts = HintUtils.getLabels(from: self.state.hints.count)
      self.state.loading = false
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
