import CoreGraphics
import SwiftUI

class SystemUtils {
  @MainActor
  static func move(_ point: CGPoint) {
    let event = CGEvent(
      mouseEventSource: nil,
      mouseType: .mouseMoved,
      mouseCursorPosition: point,
      mouseButton: .left
    )
    event?.post(tap: .cghidEventTap)
  }

  static func click() {
    if let event = CGEvent(source: nil) {
      let current = event.location
      click(current)
    }
  }

  static func click(_ point: CGPoint, _ flags: CGEventFlags = []) {
    let eventDown = CGEvent(
      mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point,
      mouseButton: .left)
    let eventUp = CGEvent(
      mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left
    )
    eventUp?.flags = flags
    eventDown?.flags = flags
    eventDown?.post(tap: .cghidEventTap)
    eventUp?.post(tap: .cghidEventTap)
  }

  static func getChar(from event: CGEvent) -> String? {
    var unicodeString = [UniChar](repeating: 0, count: 4)
    var length: Int = 0

    event.keyboardGetUnicodeString(
      maxStringLength: 4, actualStringLength: &length, unicodeString: &unicodeString)

    if length > 0 {
      return String(utf16CodeUnits: unicodeString, count: length)
    }

    return nil
  }
}
