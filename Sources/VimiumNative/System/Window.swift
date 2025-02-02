import ApplicationServices
import Cocoa
import SwiftUI

@MainActor
class Window {
  let view: AnyView
  let window = NSWindow(
    contentRect: NSMakeRect(0, 0, 0, 0),
    styleMask: [.borderless],
    backing: .buffered,
    defer: false
  )

  init(view: AnyView) {
    self.view = view
  }

  func front() -> Window {
    window.makeKeyAndOrderFront(nil)
    return self
  }

  func transparent() -> Window {
    window.isOpaque = false
    window.backgroundColor = .clear
    window.level = .floating
    window.ignoresMouseEvents = true
    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    return self
  }

  func make() -> NSWindow {
    if let screen = NSScreen.main {
      let screenFrame = screen.frame
      window.setFrame(screenFrame, display: true)
    }
    let hostingView = NSHostingView(rootView: view)
    hostingView.frame = NSRect(
      x: 0,
      y: 0,
      width: window.frame.width,
      height: window.frame.height
    )
    window.contentView?.addSubview(hostingView)

    return window
  }

}
