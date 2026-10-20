@preconcurrency import Cocoa
import CoreGraphics
import SwiftUI

@MainActor
protocol Listener: AnyObject {
  func matches(_: CGEvent) -> Bool
  func callback(_: CGEvent)
  func abort()
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

  /// Returns false if the event tap could not be created
  @discardableResult
  static func listen() -> Bool {
    if eventTap != nil {
      return true
    }
    let eventMask = (1 << CGEventType.keyDown.rawValue)
    eventTap = CGEvent.tapCreate(
      tap: .cgSessionEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: CGEventMask(eventMask),
      callback: { _, type, event, _ in

        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
          print("Global event tap was disabled (\(type.rawValue)). Recovering.")
          if let eventTap = AppEventManager.eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: true)
          }
          return Unmanaged.passUnretained(event)
        }

        let preserve = Unmanaged.passRetained(event)
        if type != .keyDown {
          return preserve
        }

        for listener in AppEventManager.listeners.reversed() {
          if listener.matches(event) {
            BenchUtils.tapTime = BenchUtils.now()
            DispatchQueue.main.async {
              listener.callback(event)

              nonisolated(unsafe) var mouseMonitor: Any? = nil
              nonisolated(unsafe) var spaceObserver: NSObjectProtocol? = nil
              nonisolated(unsafe) let listener = listener

              spaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.activeSpaceDidChangeNotification,
                object: nil,
                queue: .main
              ) { _ in
                if let monitor = mouseMonitor {
                  NSEvent.removeMonitor(monitor)
                }
                mouseMonitor = nil
                if let observer = spaceObserver {
                  NSWorkspace.shared.notificationCenter.removeObserver(observer)
                }
                spaceObserver = nil
                MainActor.assumeIsolated {
                  listener.abort()
                }
              }

              mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [
                .mouseMoved, .scrollWheel,
              ]) { event in
                guard let cgEvent = event.cgEvent else { return }
                let senderPID = cgEvent.getIntegerValueField(.eventSourceUnixProcessID)
                guard senderPID == 0 else { return }
                if let monitor = mouseMonitor {
                  NSEvent.removeMonitor(monitor)
                }
                mouseMonitor = nil
                if let observer = spaceObserver {
                  NSWorkspace.shared.notificationCenter.removeObserver(observer)
                }
                spaceObserver = nil
                listener.abort()
              }
            }

            return nil
          }
        }

        return preserve
      },
      userInfo: nil
    )

    guard let eventTap = eventTap else {
      return false
    }
    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)
    return CGEvent.tapIsEnabled(tap: eventTap)
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
  func abort() {}
}
