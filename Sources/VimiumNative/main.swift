import ApplicationServices
import Cocoa
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {

  // MARK: Properties

  private let accessibilityChecker: IAccessibilityChecker

  // MARK: Init

  override init() {
    self.accessibilityChecker = AccessibilityChecker()  // TODO: move to di from cli assembly
    super.init()
    AppEventManager.add(FzFindListener())
    AppEventManager.add(GridListener())
  }

  // MARK: NSApplicationDelegate

  func applicationDidFinishLaunching(_ notification: Notification) {
    guard accessibilityChecker.trusted else {
      print(
        """

          Missing accessibility permission! Can't work with that.

          You must allow a11y permission to the 'runner' aka your terminal client e.g. iTerm2. To do that:

            1. Go to Settings -> Privacy & Security -> Accessibility
            2. Press "+"
            3. Add your terminal app or binary path if running from a daemon
            4. Restart the vimium

        """)

      exit(0) // otherwise inf daemon restart
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
