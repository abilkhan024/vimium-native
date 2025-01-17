import Cocoa
import SwiftUI

@MainActor
class Window {
  private let window = NSWindow(
    contentRect: NSMakeRect(0, 0, 0, 0),
    styleMask: [.titled, .closable, .resizable],
    backing: .buffered,
    defer: false
  )

  public func open(view: some View) {
    window.title = AppInfo.name

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

    window.makeKeyAndOrderFront(nil)
  }
}
