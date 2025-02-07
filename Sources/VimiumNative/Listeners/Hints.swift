import CoreGraphics
import SwiftUI

struct HintElement: Hashable {
  var id: String
  var axui: AXUIElement
  var content: String?
}

@MainActor
class HintListener: Listener {
  private var globalListener: GlobalListener?
  private let hintsWindow = Window(view: AnyView(EmptyView())).transparent().make()
  private var visibleEls: [HintElement] = []
  private var input = ""

  func match(_ event: CGEvent) -> Bool {
    let flags = event.flags
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    return flags.contains(.maskCommand) && flags.contains(.maskShift)
      && (keyCode == Keys.open.rawValue || keyCode == Keys.close.rawValue)
  }

  func callback(_ event: CGEvent) {
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    switch keyCode {
    case Keys.open.rawValue:
      guard let els = ListElementsAction().exec() else {
        return print("Failed to get AXUIs")
      }
      let visibleAxuis = els.filter { el in
        guard let visible = AXUIElementUtils.isInViewport(el) else {
          return false
        }
        return visible
      }
      let seq = genLabels(from: els.count, using: "asdfghjklweruio")
      self.visibleEls = visibleAxuis.enumerated().map { idx, el in
        HintElement(id: seq[idx], axui: el, content: AXUIElementUtils.toString(el))
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
    case Keys.close.rawValue:
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
    var result: [String] = []
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

    return result
  }

  private func renderHints(_ els: [HintElement]) {
    print("Rendering \(els.count) for input \(input)")
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
    //  but i want to be able to fist by content later start typing id
    //  May be introduce special char like . that would re request new labels from current selection

    return els.filter { (e) in
      e.id.lowercased().starts(with: search) || e.content?.lowercased().contains(lower) ?? false
    }
  }

  private func onTyping(_ event: CGEvent) {
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    switch keyCode {
    case Keys.esc.rawValue:
      return onClose()
    case Keys.enter.rawValue:
      let selectedId = self.visibleEls.first?.id ?? "-1"
      print("Selecting \(selectedId)")
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
