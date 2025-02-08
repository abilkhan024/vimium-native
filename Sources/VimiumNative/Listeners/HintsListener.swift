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
  private let hintsWindow = Window(view: AnyView(EmptyView())).transparent().make()

  private var visibleEls: [HintElement] = []
  private var renderedEls: [HintElement] = []
  private var input = ""
  private var labelSeq: [String] = []

  func match(_ event: CGEvent) -> Bool {
    let flags = event.flags
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    return flags.contains(.maskCommand) && flags.contains(.maskShift)
      && (keyCode == Keys.dot.rawValue || keyCode == Keys.comma.rawValue)
  }

  func callback(_ event: CGEvent) {
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    switch keyCode {
    case Keys.dot.rawValue:
      guard let els = ListElementsAction().exec() else {
        return print("Failed to get AXUIs")
      }
      let visibleAxuis = els.filter { el in
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
      hintsWindow.makeKeyAndOrderFront(nil)
      break
    case Keys.comma.rawValue:
      return onClose()
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
    hintsWindow.orderOut(nil)
  }

  private func genLabels(from n: Int, using _chars: String) -> [String] {
    var result: [String] = labelSeq
    let chars = _chars.split(separator: "").map { sub in String(sub) }
    var q: [String] = chars

    if q.isEmpty {
      return result
    }

    while result.count < n {
      let cur = q.first!
      for char in chars {
        let next = cur + char
        result.append(next)
        if result.count == n {
          break
        }
        q.append(next)
      }
      q = Array(q.dropFirst())
    }
    labelSeq = result

    return result
  }

  private func renderHints(_ els: [HintElement]) {
    renderedEls = els
    if els.isEmpty {
      hintsWindow.contentView = nil
    } else {
      let hintsView = HintsView(els: els)
      hintsWindow.contentView = NSHostingView(rootView: AnyView(hintsView))
      hintsWindow.makeKeyAndOrderFront(nil)
    }
  }

  private func getChar(from event: CGEvent) -> String? {
    var unicodeString = [UniChar](repeating: 0, count: 4)
    var length: Int = 0

    event.keyboardGetUnicodeString(
      maxStringLength: 4, actualStringLength: &length, unicodeString: &unicodeString)

    if length > 0 {
      return String(utf16CodeUnits: unicodeString, count: length)
    }

    return nil
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
    let eventDown = CGEvent(
      mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point,
      mouseButton: .left)
    let eventUp = CGEvent(
      mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left
    )
    eventDown?.post(tap: .cghidEventTap)
    eventUp?.post(tap: .cghidEventTap)
    print("Selecting \(el.id)")
  }

  private func axuiToHint(_ count: Int, _ idx: Int, _ el: AXUIElement) -> HintElement {
    let seq = genLabels(from: count, using: AppOptions.load().hintChars)
    var hint = HintElement(id: seq[idx], axui: el, content: AXUIElementUtils.toString(el))
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
      guard let char = getChar(from: event) else { return }
      input.append(char)
      return renderHints(searchEls(els: self.visibleEls, search: input))
    }
  }
}
