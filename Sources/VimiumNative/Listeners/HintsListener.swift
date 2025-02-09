import CoreGraphics
import SwiftUI

struct HintElement: Hashable {
  var id: String
  var axui: AXUIElement
  var content: String?
  var position: CGPoint?
}

@MainActor
class HintListener: Listener {
  private var globalListener: GlobalListener?
  private let window = Window.get()

  private var visibleEls: [HintElement] = []
  private var renderedEls: [HintElement] = []
  private var input = ""

  func match(_ event: CGEvent) -> Bool {
    let flags = event.flags
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    return flags.contains(.maskCommand) && flags.contains(.maskShift)
      && keyCode == Keys.dot.rawValue
  }

  func callback(_ event: CGEvent) {
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    switch keyCode {
    case Keys.dot.rawValue:
      guard let els = ListElementsAction().exec() else {
        return print("Failed to get AXUIs")
      }
      let visibleAxuis = els.filter { (el) in
        guard let visible = AXUIElementUtils.isInViewport(el) else {
          return false
        }
        return visible
      }
      self.visibleEls = visibleAxuis.enumerated().map { idx, el in
        axuiToHint(visibleAxuis.count, idx, el)
      }
      input = ""
      if let prev = globalListener {
        AppEventManager.remove(prev)
      }
      globalListener = GlobalListener(onEvent: self.onTyping)
      AppEventManager.add(globalListener!)
      renderHints(visibleEls)
      window.front().call()
      break
    default:
      print("Impossible case exectued")
    }
  }

  private func onClose() {
    if let listener = globalListener {
      AppEventManager.remove(listener)
      globalListener = nil
    }
    input = ""
    window.hide().call()
  }

  private func renderHints(_ els: [HintElement]) {
    renderedEls = els
    if els.isEmpty {
      window.clear().call()
    } else {
      window.render(AnyView(HintsView(els: els)))
        .front()
        .call()
    }
    NSCursor.hide()
    print("Rendering \(els.count)")
  }

  private func searchEls(els: [HintElement], search: String) -> [HintElement] {
    if search.isEmpty {
      return els
    }
    let lower = search.lowercased()

    return els.filter { (e) in
      e.id.lowercased().starts(with: search) || e.content?.lowercased().contains(lower) ?? false
    }
  }

  private func selectEl(_ el: HintElement) {
    guard let point = el.position else { return }
    SystemUtils.click(point)
    print("Selecting \(el.id)")  // shortcut for click to current position again?
  }

  private func axuiToHint(_ count: Int, _ idx: Int, _ el: AXUIElement) -> HintElement {
    let seq = HintUtils.genLabels(from: count)
    let id = seq[idx]
    var hint = HintElement(id: id, axui: el, content: AXUIElementUtils.toString(el))
    if let point = AXUIElementUtils.getPoint(el),
      let size = AXUIElementUtils.getSize(el)
    {
      hint.position = CGPointMake(point.x + size.width / 2, point.y + size.height / 2)
    }

    return hint
  }

  private func onTyping(_ event: CGEvent) {
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    switch keyCode {
    case Keys.esc.rawValue:
      return onClose()
    case Keys.dot.rawValue:
      self.visibleEls = self.renderedEls.enumerated().map { (idx, el) in
        axuiToHint(self.renderedEls.count, idx, el.axui)
      }
      self.input = ""
      return renderHints(self.visibleEls)
    case Keys.enter.rawValue:
      if let first = self.renderedEls.count == 1 ? self.renderedEls.first : nil {
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
}
