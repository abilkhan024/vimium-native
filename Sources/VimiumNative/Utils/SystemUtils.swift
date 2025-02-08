import CoreGraphics

class SystemUtils {
  static func click(_ point: CGPoint) {
    let eventDown = CGEvent(
      mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point,
      mouseButton: .left)
    let eventUp = CGEvent(
      mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left
    )
    eventDown?.post(tap: .cghidEventTap)
    eventUp?.post(tap: .cghidEventTap)
  }
}
