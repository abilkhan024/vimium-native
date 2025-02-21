import ApplicationServices
import Cocoa
import CoreFoundation
import CoreGraphics
import SwiftUI

@_silgen_name("CGSSetConnectionProperty")
func CGSSetConnectionProperty(
  _ connection: Int, _ connection2: Int, _ property: CFString, _ value: CFBoolean)

@_silgen_name("_CGSDefaultConnection")
func _CGSDefaultConnection() -> Int

@MainActor
class WindowBuilder {
  private let window = NSWindow(
    contentRect: NSMakeRect(0, 0, 0, 0),
    styleMask: [.borderless],
    backing: .buffered,
    defer: false
  )

  private func resizeToFit() {
    if let screen = NSScreen.main {
      let screenFrame = screen.frame
      window.setFrame(screenFrame, display: true)
    }
  }

  init() {
    window.isOpaque = false
    window.backgroundColor = .clear
    window.level = .screenSaver
    window.ignoresMouseEvents = true
    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

    resizeToFit()
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
    resizeToFit()
    window.makeKeyAndOrderFront(nil)
    return self
  }

  func hideCursor() -> WindowBuilder {
    let propertyString = CFStringCreateWithCString(
      nil, "SetsCursorInBackground", CFStringBuiltInEncodings.UTF8.rawValue)
    CGSSetConnectionProperty(
      _CGSDefaultConnection(), _CGSDefaultConnection(), propertyString!, kCFBooleanTrue)

    CGDisplayHideCursor(CGMainDisplayID())
    return self
  }

  func showCursor() -> WindowBuilder {
    CGDisplayShowCursor(CGMainDisplayID())
    return self
  }

  func hide() -> WindowBuilder {
    window.orderOut(nil)
    showCursor().call()
    return self
  }

  func clear() -> WindowBuilder {
    window.contentView = nil
    showCursor().call()
    return self
  }

  func render(_ view: AnyView) -> WindowBuilder {
    window.contentView = NSHostingView(rootView: view)
    return self
  }

  func native() -> NSWindow {
    resizeToFit()
    return window
  }

  // Fake stub to prevent warning for unused result
  // Could potentially use for lazy eval
  func call() {}
}
