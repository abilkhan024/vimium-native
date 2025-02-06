import CoreGraphics
import SwiftUI

@MainActor
class HintListener: Listener {
  enum Keys: Int64 {
    case openTag = 47
    case closeTag = 43
  }

  private static var overlayWindow: NSWindow?

  var match: (_ event: CGEvent) -> Bool = { event in
    let flags = event.flags
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    return flags.contains(.maskCommand) && flags.contains(.maskShift)
      && (keyCode == Keys.openTag.rawValue || keyCode == Keys.closeTag.rawValue)
  }

  var callback: (_ event: CGEvent) -> Void = { event in
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    print("Callback executed \(keyCode)!")

    switch keyCode {
    case Keys.openTag.rawValue:
      guard let els = ListElementsAction().exec() else {
        return print("Failed to get AXUIs")
      }
      let hintsView = HintsView(els: els)
      if let win = overlayWindow {
        win.contentView = NSHostingView(rootView: AnyView(hintsView))
        win.makeKeyAndOrderFront(nil)
      } else {
        overlayWindow = Window(view: AnyView(hintsView)).transparent().front()
          .make()
      }
      break
    case Keys.closeTag.rawValue:
      overlayWindow?.orderOut(nil)
      break
    default:
      print("Impossible case exectued")
    }

  }
}
