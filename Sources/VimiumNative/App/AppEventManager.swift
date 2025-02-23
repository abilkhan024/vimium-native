@preconcurrency import Cocoa
import CoreGraphics
import SwiftUI

// REF: https://eastmanreference.com/complete-list-of-applescript-key-codes
enum Keys: Int64 {
  case dot = 47
  case comma = 43
  case esc = 53
  case enter = 36
  case backspace = 51
  case left = 123
  case right = 124
  case down = 125
  case up = 126
  case quote = 39
  case slash = 44
  case semicolon = 41
  case tab = 48

  case h = 4
  case j = 38
  case k = 40
  case l = 37
  case v = 9
  case m = 46
  case d = 2
  case u = 32
  case g = 5

  case one = 18
  case two = 19
  case three = 20
  case four = 21
  case five = 23
  case six = 22
  case seven = 26
  case eight = 28
  case nine = 25
  case zero = 29
}

@MainActor
protocol Listener: AnyObject {
  func match(_: CGEvent) -> Bool
  func callback(_: CGEvent)
}

/// Static only because for some reason swift
/// refuses to compile when `self` is refernced
/// from `CGEvent.tapCreate` callback
@MainActor
class AppEventManager {
  private static var eventTap: CFMachPort?
  private static var listeners: [Listener] = []

  static func add(_ listener: Listener) {
    listeners.append(listener)
  }

  static func remove(_ listener: Listener) {
    if let idx = listeners.firstIndex(where: { (el) in listener === el }) {
      listeners.remove(at: idx)
    }
  }

  static func listen() {
    let eventMask = (1 << CGEventType.keyDown.rawValue)
    eventTap = CGEvent.tapCreate(
      tap: .cgSessionEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: CGEventMask(eventMask),
      callback: { _, type, event, _ in

        let preserve = Unmanaged.passRetained(event)
        if type != .keyDown {
          return preserve
        }

        for listener in AppEventManager.listeners {
          if listener.match(event) {
            DispatchQueue.main.async { listener.callback(event) }
            return nil
          }
        }

        return preserve
      },
      userInfo: nil
    )

    if let eventTap = eventTap {
      let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
      CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
      CGEvent.tapEnable(tap: eventTap, enable: true)
    }
  }

  static func stop() {
    if let eventTap = eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: false)
      self.listeners.removeAll()
    }
  }
}

/// Listens to all key strokes usage assumes there will be declared some sort
/// of term key to stop it
@MainActor
class AppListener: Listener {
  let onEvent: (_ event: CGEvent) -> Void

  init(onEvent: @escaping (_ event: CGEvent) -> Void) {
    self.onEvent = onEvent
  }

  func match(_ event: CGEvent) -> Bool {
    return true
  }

  func callback(_ event: CGEvent) {
    onEvent(event)
  }
}
