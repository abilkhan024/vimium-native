import CoreGraphics
import SwiftUI

@MainActor
class HintListener: Listener {
  private var globalListener: GlobalListener?
  private let hintsWindow = Window(view: AnyView(EmptyView())).transparent().make()

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
      let visibleEls = els.filter { el in
        guard let visible = AXUIElementUtils.isInViewport(el) else {
          return false
        }
        return visible
      }
      print("Visible \(visibleEls.count), all els \(els.count)")
      globalListener = GlobalListener(onEvent: self.onTyping)
      AppEventManager.add(globalListener!)
      let hintsView = HintsView(els: visibleEls)
      hintsWindow.contentView = NSHostingView(rootView: AnyView(hintsView))
      hintsWindow.makeKeyAndOrderFront(nil)
      break
    case Keys.close.rawValue:
      return onClose()
    default:
      print("Impossible case exectued")
    }
  }

  private func onClose() {
    hintsWindow.orderOut(nil)
  }

  private func onTyping(_ event: CGEvent) {
    guard let listener = globalListener else {
      return
    }
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    if keyCode == Keys.esc.rawValue {
      AppEventManager.remove(listener)
      return onClose()
    }
    print(keyCode)
  }
}
