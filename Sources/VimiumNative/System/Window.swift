import ApplicationServices
import Cocoa
import SwiftUI

@MainActor
class Window {
  private static let shared = Window()
  private static let window = NSWindow(
    contentRect: NSMakeRect(0, 0, 0, 0),
    styleMask: [.borderless],
    backing: .buffered,
    defer: false
  )

  private init() {
    Window.window.isOpaque = false
    Window.window.backgroundColor = .clear
    Window.window.level = .screenSaver
    Window.window.ignoresMouseEvents = true
    Window.window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

    if let screen = NSScreen.main {
      let screenFrame = screen.frame
      Window.window.setFrame(screenFrame, display: true)
    }
    let hostingView = NSHostingView(rootView: AnyView(EmptyView()))
    hostingView.frame = NSRect(
      x: 0,
      y: 0,
      width: Window.window.frame.width,
      height: Window.window.frame.height
    )
    Window.window.contentView?.addSubview(hostingView)
  }

  static func get() -> Window {
    return shared
  }

  func front() -> Window {
    Window.window.makeKeyAndOrderFront(nil)
    return self
  }

  func hide() -> Window {
    Window.window.orderOut(nil)
    return self
  }

  func clear() -> Window {
    Window.window.contentView = nil
    return self
  }

  func render(_ view: AnyView) -> Window {
    Window.window.contentView = NSHostingView(rootView: view)
    Window.window.makeKeyAndOrderFront(nil)
    return self
  }

  func native() -> NSWindow {
    return Window.window
  }

  // Fake stub to prevent warning for unused result
  // Could potentially use for lazy eval
  func call() {}
}
