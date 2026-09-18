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
    if !AXIsProcessTrustedWithOptions(nil) {
      print(
        """

          AXIsProcessTrusted is false! Can't work with that.

          You must allow Accessibility permission to Vimium Native.

            1. Go to Settings -> Privacy & Security -> Accessibility
            2. Press "+"
            3. Add Vimium Native.app
            4. Restart the vimium

        """)

      exit(1)
    }
    if !CGPreflightListenEventAccess() {
      CGRequestListenEventAccess()
      print("Input Monitoring permission is required. Add Vimium Native.app and restart it.")
      exit(1)
    }
    guard AppEventManager.listen() else {
      print("Unable to enable the global event tap. Restart Vimium Native after granting Input Monitoring permission.")
      exit(1)
    }
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
