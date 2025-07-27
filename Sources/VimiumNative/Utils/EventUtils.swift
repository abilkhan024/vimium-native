import AppKit
import CoreGraphics
import SwiftUI

class EventUtils {
  static func move(_ target: CGPoint, type: CGEventType = .mouseMoved) {
    let point = normalizePoint(target)
    let event = CGEvent(
      mouseEventSource: nil,
      mouseType: type,
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

  private static func postMouse(
    _ type: CGEventType,
    _ button: CGMouseButton,
    _ point: CGPoint,
    _ flags: CGEventFlags = [],
    count: Int = 1
  ) {
    let eventDown = CGEvent(
      mouseEventSource: nil, mouseType: type, mouseCursorPosition: point,
      mouseButton: button)
    eventDown?.flags = flags
    eventDown?.setIntegerValueField(.mouseEventClickState, value: Int64(count))
    eventDown?.post(tap: .cghidEventTap)
  }

  static func leftMouseDown(_ point: CGPoint, _ flags: CGEventFlags = [], count: Int = 1) {
    postMouse(.leftMouseDown, .left, point, flags, count: count)
  }

  static func leftMouseUp(_ point: CGPoint, _ flags: CGEventFlags = [], count: Int = 1) {
    postMouse(.leftMouseUp, .left, point, flags, count: count)
  }

  static func leftClick(_ point: CGPoint, _ flags: CGEventFlags = [], count: Int = 1) {
    leftMouseDown(point, flags, count: count)
    leftMouseUp(point, flags, count: count)
  }

  static func rightClick(_ point: CGPoint, _ flags: CGEventFlags = []) {
    postMouse(.rightMouseDown, .right, point, flags)
    postMouse(.rightMouseUp, .right, point, flags)
  }

  static func getEventChar(from event: CGEvent) -> String? {
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
