import Cocoa
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
  override init() {
    super.init()
    AppEventManager.add(FzFindListener())
    AppEventManager.add(GridListener())
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    if !AXIsProcessTrusted() {
      return print("AXIsProcessTrusted is false, allow a11y to the runner")
    }
    AppEventManager.listen()
    print("Listening to trigger key")
  }

  func applicationWillTerminate(_ notification: Notification) {
    AppEventManager.stop()
  }
}

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.setActivationPolicy(NSApplication.ActivationPolicy.accessory)
AppCommands.shared.run()
