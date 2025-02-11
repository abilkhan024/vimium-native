import CoreGraphics
import SwiftUI

@MainActor
class FzFindListener: Listener {
  private let hintsWindow = FzFindWindowManager.get(.hints)
  private var appListener: AppListener?
  private let state = FzFindState.shared

  private var visibleEls: [HintElement] = []
  private var input = ""

  init() {
    // something like this but doesn't block and works better?
    // Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
    //   DispatchQueue.global(qos: .background).asyncAfter(deadline: .now()) {  // Example: Delay by 100ms
    //     DispatchQueue.main.async {
    //       self.reval()
    //     }
    //   }
    // }

    // make reval on some key stroke e.g if cmd is pressed may be?
    hintsWindow.render(AnyView(FzFindHintsView())).call()
  }

  private func reval() {
    state.loading = true
    guard let els = ListElementsAction().exec() else {
      print("Failed to get AXUIs")
      return
    }

    self.visibleEls = els.filter { (el) in
      guard let visible = AxElementUtils.isInViewport(el) else {
        return false
      }
      return visible
    }.enumerated().map { idx, el in self.axuiToHint(els.count, idx, el) }
    self.state.hints = self.visibleEls
    state.loading = false
  }

  func match(_ event: CGEvent) -> Bool {
    let flags = event.flags
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    return flags.contains(.maskCommand) && flags.contains(.maskShift)
      && keyCode == Keys.dot.rawValue
  }

  func callback(_ event: CGEvent) {
    input = ""
    if let prev = appListener {
      AppEventManager.remove(prev)
    }
    appListener = AppListener(onEvent: self.onTyping)
    AppEventManager.add(appListener!)

    DispatchQueue.main.async {
      self.reval()
      print(self.state.hints.count, "rendered")
    }
    hintsWindow.front().call()

    // switch keyCode {
    // case Keys.dot.rawValue:
    //   break
    // default:
    //   print("Impossible case exectued")
    // }
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
      self.reval()
    }
  }

  private func selectEl(_ el: HintElement) {
    guard let point = el.position else { return }
    SystemUtils.click(point)
    print("Selecting \(el.id)")  // shortcut for click to current position again?
  }

  private func onTyping(_ event: CGEvent) {
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    switch keyCode {
    case Keys.esc.rawValue:
      return onClose()
    case Keys.dot.rawValue:
      self.visibleEls = self.state.hints.enumerated().map { (idx, el) in
        axuiToHint(self.state.hints.count, idx, el.axui)
      }
      self.input = ""
      return renderHints(self.visibleEls)
    case Keys.enter.rawValue:
      if let first = self.state.hints.count == 1 ? self.state.hints.first : nil {
        self.selectEl(first)
      }
      return onClose()
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
    state.hints = els
    NSCursor.hide()
  }

}
