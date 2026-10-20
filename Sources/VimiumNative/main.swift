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
    let missing = missingPermissions(prompt: true)
    if !missing.isEmpty {
      exitWithPermissionHint(missing)
    }
    if !AppEventManager.listen() {
      exitWithPermissionHint(["Accessibility", "Input Monitoring"], reason: "Failed to create event tap.")
    }
    print("Listening to trigger key")
  }

  /// Returns names of the missing permissions required for the event tap.
  /// `.defaultTap` (able to swallow events) requires Accessibility,
  /// receiving key events from other apps requires Input Monitoring.
  /// When `prompt` is true macOS shows its permission dialogs and adds
  /// the runner app to the respective lists in System Settings.
  private func missingPermissions(prompt: Bool = false) -> [String] {
    var missing: [String] = []
    // Raw value of `kAXTrustedCheckOptionPrompt`, the global isn't concurrency-safe
    let axOptions = ["AXTrustedCheckOptionPrompt": prompt] as CFDictionary
    if !AXIsProcessTrustedWithOptions(axOptions) {
      missing.append("Accessibility")
    }
    if !CGPreflightListenEventAccess() {
      if prompt {
        CGRequestListenEventAccess()
      }
      missing.append("Input Monitoring")
    }
    return missing
  }

  private func exitWithPermissionHint(_ permissions: [String], reason: String? = nil) -> Never {
    let list = permissions.joined(separator: ", ")
    print(
      """

        \(reason ?? "Missing permissions: \(list).") Can't work with that.

        You must allow \(list) permission to the 'runner' aka your terminal client e.g. iTerm2.
        For each of: \(list)

          1. Go to Settings -> Privacy & Security -> <Permission>
          2. Press "+" (or toggle the entry if it's already listed)
          3. Add your terminal app
          4. Restart the vimium

      """)
    exit(1)
  }

  func applicationWillTerminate(_ notification: Notification) {
    AppEventManager.stop()
  }
}

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.setActivationPolicy(NSApplication.ActivationPolicy.accessory)
AppCommands.shared.run()
