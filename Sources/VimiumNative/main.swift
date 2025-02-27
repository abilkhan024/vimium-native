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
      print(
        """

          AXIsProcessTrusted is false! Can't work with that.

          You must allow a11y permission to the 'runner' aka your terminal client e.g. iTerm2. To do that:

            1. Go to Settings -> Privacy & Security -> Accessibility
            2. Press "+"
            3. Add your terminal app
            4. Restart the vimium

        """)

      exit(1)
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
