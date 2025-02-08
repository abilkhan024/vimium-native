import CoreGraphics
import SwiftUI

@MainActor
class MouseListener: Listener {
  func match(_ event: CGEvent) -> Bool {
    let flags = event.flags
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    return flags.contains(.maskCommand) && flags.contains(.maskShift)
      && keyCode == Keys.comma.rawValue
  }

  func callback(_ event: CGEvent) {
    // Window.get().open(AnyView(MouseView(position: CGPointMake(50, 50))))
    // print("Mouse")
  }
}
