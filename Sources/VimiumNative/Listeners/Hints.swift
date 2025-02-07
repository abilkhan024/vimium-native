import CoreGraphics
import SwiftUI

struct HintElement: Hashable {
  var axui: AXUIElement
  var id: String
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
      // DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
      //   if self.input != "" {
      //     NSApplication.shared.terminate(nil)
      //   }
      // }
      let visibleEls = els.filter { el in
        guard let visible = AXUIElementUtils.isInViewport(el) else {
          return false
        }
        return visible
      }.enumerated().map { idx, el in HintElement(axui: el, id: String(idx)) }
      self.visibleEls = visibleEls
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

  private func renderHints(_ els: [HintElement]) {
    let hintsView = HintsView(els: els)
    hintsWindow.contentView = NSHostingView(rootView: AnyView(hintsView))
    hintsWindow.makeKeyAndOrderFront(nil)
    print("Rendering \(els.count)")
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
      return renderHints(self.visibleEls.filter { (e) in e.id.starts(with: input) })
    default:
      guard let char = getChar(from: event) else { return }
      input.append(char)
      return renderHints(self.visibleEls.filter { (e) in e.id.starts(with: input) })
    }
  }
}
