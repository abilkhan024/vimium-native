import AppKit
import CoreGraphics
import SwiftUI

class SystemUtils {
  static func move(_ target: CGPoint) {
    let point = normalizePoint(target)
    let event = CGEvent(
      mouseEventSource: nil,
      mouseType: .mouseMoved,
      mouseCursorPosition: point,
      mouseButton: .left
    )
    event?.post(tap: .cghidEventTap)
  }

  static func scroll(deltaY: Int32, deltaX: Int32 = 0) {
    let event = CGEvent(
      scrollWheelEvent2Source: nil,
      units: .pixel,
      wheelCount: 2,
      wheel1: deltaY,
      wheel2: deltaX,
      wheel3: 0)
    event?.post(tap: .cghidEventTap)
  }

  static func normalizePoint(_ target: CGPoint) -> CGPoint {
    var point = target
    guard let screen = NSScreen.main else { return point }
    if point.y < screen.frame.minY {
      point.y = screen.frame.minY
    } else if point.y > screen.frame.maxY {
      point.y = screen.frame.maxY
    }
    if point.x < screen.frame.minX {
      point.x = screen.frame.minX
    } else if point.x > screen.frame.maxX {
      point.x = screen.frame.maxX
    }
    return point
  }

  static func click() {
    if let event = CGEvent(source: nil) {
      let current = event.location
      click(current)
    }
  }

  static func mouseDown(_ point: CGPoint, _ flags: CGEventFlags = []) {
    let eventDown = CGEvent(
      mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point,
      mouseButton: .left)
    eventDown?.flags = flags
    eventDown?.post(tap: .cghidEventTap)
  }

  static func mouseUp(_ point: CGPoint, _ flags: CGEventFlags = []) {
    let eventUp = CGEvent(
      mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left
    )
    eventUp?.flags = flags
    eventUp?.post(tap: .cghidEventTap)
  }

  static func click(_ point: CGPoint, _ flags: CGEventFlags = []) {
    mouseDown(point, flags)
    mouseUp(point, flags)
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
