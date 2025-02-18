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
      leftClick(current)
    }
  }

  static func leftMouseDown(_ point: CGPoint, _ flags: CGEventFlags = []) {
    postMouse(.leftMouseDown, .left, point, flags)
  }

  static func leftMouseUp(_ point: CGPoint, _ flags: CGEventFlags = []) {
    postMouse(.leftMouseUp, .left, point, flags)
  }

  static func leftClick(_ point: CGPoint, _ flags: CGEventFlags = []) {
    leftMouseDown(point, flags)
    leftMouseUp(point, flags)
  }

  static func rightClick(_ point: CGPoint, _ flags: CGEventFlags = []) {
    postMouse(.rightMouseDown, .right, point, flags)
    postMouse(.rightMouseUp, .right, point, flags)
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

  private static func postMouse(
    _ type: CGEventType,
    _ button: CGMouseButton,
    _ point: CGPoint,
    _ flags: CGEventFlags = []
  ) {
    let eventDown = CGEvent(
      mouseEventSource: nil, mouseType: type, mouseCursorPosition: point,
      mouseButton: button)
    eventDown?.flags = flags
    eventDown?.post(tap: .cghidEventTap)
  }

}
