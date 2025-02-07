@preconcurrency import Cocoa
import CoreGraphics
import SwiftUI

enum Keys: Int64 {
  case open = 47
  case close = 43
  case esc = 53
  case enter = 36
  case backspace = 51
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
