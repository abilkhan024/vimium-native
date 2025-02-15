import CoreGraphics
import SwiftUI

@MainActor
class FzFindListener: Listener {
  private let hintsWindow = FzFindWindowManager.get(.hints)
  private var appListener: AppListener?
  private let state = FzFindState.shared

  private var visibleEls: [HintElement] = []
  private var input = ""
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

  // Doesn't account rect of parent
  // Can check when opening extensions of chrome
  func isHintable(_ el: AXUIElement) -> Bool {
    guard let role = AxElementUtils.getAttributeString(el, kAXRoleAttribute) else {
      return false
    }
    if role == "AXRow" {
      print("Not yet handled")
    }
    if role == "AXWindow" || role == "AXScrollArea" {
      return false
    }

    return isActionable(el) || isRowWithoutHintableChildren(el)
  }

  func isActionable(_ el: AXUIElement) -> Bool {
    var names: CFArray?
    let error = AXUIElementCopyActionNames(el, &names)

    if error == .noValue || error == .attributeUnsupported {
      return false
    }

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

    return actions.count > count
  }

  func isRowWithoutHintableChildren(_ el: AXUIElement) -> Bool {
    return false
  }

  func getHintableLeafs(_ el: AXUIElement, _ w: CGFloat, _ h: CGFloat) -> [AXUIElement] {
    let elIsHintable = isHintable(el)
    var children: CFTypeRef?
    let visible = AxElementUtils.isInViewport(el, w, h)

    let childResult = AXUIElementCopyAttributeValue(
      el, kAXChildrenAttribute as CFString, &children)
    guard childResult == .success, let childrenEls = children as? [AXUIElement], visible != false
    else {
      return elIsHintable ? [el] : []
    }
    var result: [AXUIElement] = []
    for child in childrenEls {
      result.append(contentsOf: getHintableLeafs(child, w, h))
    }
    if result.isEmpty && elIsHintable {
      result.append(el)
    }

    return result
  }

  func getVisibleEls() -> [AXUIElement] {
    let app = NSWorkspace.shared.frontmostApplication!
    let pid = app.processIdentifier

    let appEl = AXUIElementCreateApplication(pid)
    var els: [AXUIElement] = []
    let h = self.hintsWindow.native().frame.height
    let w = self.hintsWindow.native().frame.width

    var stack = [appEl]
    while !stack.isEmpty {
      let sub = stack.popLast()!
      let visible = AxElementUtils.isInViewport(sub, w, h)
      let subIsHintable = isHintable(sub)

      if visible != false {
        els.append(contentsOf: getHintableLeafs(sub, w, h))
      } else if subIsHintable && visible == true {
        els.append(sub)
      }
    }

    return els
  }

  func callback(_ event: CGEvent) {
    input = ""
    if let prev = appListener {
      AppEventManager.remove(prev)
    }
    appListener = AppListener(onEvent: self.onTyping)
    AppEventManager.add(appListener!)
    hintsWindow.front().call()

    let start = DispatchTime.now().uptimeNanoseconds
    let els = getVisibleEls()
    print("BFS took \(DispatchTime.now().uptimeNanoseconds - start) Got \(els.count)")
    self.state.hints = els.map { e in AxElement(e) }.filter { e in e.point != nil }
    self.state.texts = HintUtils.getLabels(from: self.state.hints.count)
    self.hintsWindow.front().call()

    if let prev = self.appListener {
      AppEventManager.remove(prev)
    }
    self.appListener = AppListener(onEvent: self.onTyping)
    AppEventManager.add(self.appListener!)

    print("Took \(DispatchTime.now().uptimeNanoseconds - start) Got \(els.count)")
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
      self.input = ""
    }
  }

  private func selectEl(_ el: HintElement) {
    guard let point = el.position else { return }
    SystemUtils.click(point)
    print("Selecting \(el.id)")
  }

  private func onTyping(_ event: CGEvent) {
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    switch keyCode {
    case Keys.esc.rawValue:
      return onClose()
    case Keys.dot.rawValue:
      break
    // self.visibleEls = self.state.hints.enumerated().map { (idx, el) in
    //   axuiToHint(self.state.hints.count, idx, el.axui)
    // }
    // self.input = ""
    // return renderHints(self.visibleEls)
    case Keys.enter.rawValue:
      break
    // if let first = self.state.hints.count == 1 ? self.state.hints.first : nil {
    //   self.selectEl(first)
    // }
    // return onClose()
    case Keys.backspace.rawValue:
      input = String(input.dropLast())
      if input.isEmpty {
        return renderHints(self.visibleEls)
      }
      return renderHints(searchEls(els: self.visibleEls, search: input))
    default:
      guard let char = SystemUtils.getChar(from: event) else { return }
      input.append(char)
      return renderHints(searchEls(els: self.visibleEls, search: input))
    }
  }

  private func searchEls(els: [HintElement], search: String) -> [HintElement] {
    if search.isEmpty {
      return els
    }
    // let lower = search.lowercased()

    return els.filter { (e) in
      e.id.lowercased().starts(
        with: search) /* || e.content?.lowercased().contains(lower) ?? false */
    }
  }

  private func renderHints(_ els: [HintElement]) {
    if els.isEmpty {
      hintsWindow.hide().call()
    }
    // state.hints = els
    NSCursor.hide()
  }

}
