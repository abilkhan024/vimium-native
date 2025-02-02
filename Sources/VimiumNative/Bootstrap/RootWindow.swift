import ApplicationServices
import Cocoa
import SwiftUI

@MainActor
class RootWindow {
  private var window = NSWindow(
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
    window.contentView?.subviews.removeAll()
    window.contentView?.addSubview(hostingView)
    window.makeKeyAndOrderFront(nil)
  }

  func close() {
    window.close()

    window = NSWindow(
      contentRect: NSMakeRect(0, 0, 0, 0),
      styleMask: [.titled, .closable, .resizable],
      backing: .buffered,
      defer: false
    )
  }
}
