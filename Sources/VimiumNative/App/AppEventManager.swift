@preconcurrency import Cocoa
import CoreGraphics
import SwiftUI

@MainActor
protocol Listener: AnyObject {
  func matches(_: CGEvent) -> Bool
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
          if listener.matches(event) {
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

  func matches(_ event: CGEvent) -> Bool {
    return true
  }

  func callback(_ event: CGEvent) {
    onEvent(event)
  }
}
