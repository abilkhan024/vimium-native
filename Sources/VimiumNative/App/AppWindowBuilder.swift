import ApplicationServices
import Cocoa
import SwiftUI

@MainActor
class WindowBuilder {
  private let window = NSWindow(
    contentRect: NSMakeRect(0, 0, 0, 0),
    styleMask: [.borderless],
    backing: .buffered,
    defer: false
  )

  init() {
    window.isOpaque = false
    window.backgroundColor = .clear
    window.level = .screenSaver
    window.ignoresMouseEvents = true
    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

    if let screen = NSScreen.main {
      let screenFrame = screen.frame
      window.setFrame(screenFrame, display: true)
    }
    let hostingView = NSHostingView(rootView: AnyView(EmptyView()))
    hostingView.frame = NSRect(
      x: 0,
      y: 0,
      width: window.frame.width,
      height: window.frame.height
    )
    window.contentView?.addSubview(hostingView)
  }

  func front() -> WindowBuilder {
    window.makeKeyAndOrderFront(nil)
    return self
  }

  func hide() -> WindowBuilder {
    window.orderOut(nil)
    return self
  }

  func clear() -> WindowBuilder {
    window.contentView = nil
    return self
  }

  func render(_ view: AnyView) -> WindowBuilder {
    window.contentView = NSHostingView(rootView: view)
    return self
  }

  func native() -> NSWindow {
    return window
  }

  // Fake stub to prevent warning for unused result
  // Could potentially use for lazy eval
  func call() {}
}
