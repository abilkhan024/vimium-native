@preconcurrency import Cocoa
import CoreGraphics
import SwiftUI

@MainActor
class AppListeners {
  private var eventTap: CFMachPort?
  private static var overlayWindow: NSWindow?

  func listen() {
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

        let flags = event.flags
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        if !flags.contains(.maskCommand) || !flags.contains(.maskShift) {
          return preserve
        }

        switch keyCode {
        case 47:
          DispatchQueue.main.async {
            guard let hintsView = ListElementsAction().exec() else {
              return print("Failed to get HintsView")
            }
            if let win = AppListeners.overlayWindow {
              win.contentView = NSHostingView(rootView: AnyView(hintsView))
              win.makeKeyAndOrderFront(nil)
            } else {
              AppListeners.overlayWindow = Window(view: AnyView(hintsView)).transparent().front()
                .make()
            }
          }
          return nil
        case 43:
          DispatchQueue.main.async {
            AppListeners.overlayWindow?.orderOut(nil)
          }
          return nil
        default:
          return preserve
        }
      },
      userInfo: nil
    )

    if let eventTap = eventTap {
      let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
      CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
      CGEvent.tapEnable(tap: eventTap, enable: true)
    }

  }

  func stop() {
    if let eventTap = eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: false)
    }
  }

}
