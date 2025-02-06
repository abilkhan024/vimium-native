import Cocoa

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
  let listeners = AppListeners()

  func applicationDidFinishLaunching(_ notification: Notification) {
    listeners.listen()
  }
}

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
