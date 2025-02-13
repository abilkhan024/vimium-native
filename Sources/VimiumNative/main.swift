import Cocoa
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
  override init() {
    super.init()
    // AppEventManager.add(FzFindListener())
    AppEventManager.add(FzFindFastListener())
    // AppEventManager.add(GridListener())
  }

  func perf() {
    // ----
    // poll, but is polling 10k elems is any faster, or may be purge every n
    // elements? purge if the role is not avialable
    // ----
    // keep track of the window and if the window is visible?, nahh,
    // may be dfs from parent if parent is not available it's safe to assume
    // ----
    // set some max per tick?
    // ----
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    if !AXIsProcessTrusted() {
      return print("AXIsProcessTrusted is false")
    }
    AppEventManager.listen()
    // print("Listening to trigger key")
    // self.perf()
  }

  func applicationWillTerminate(_ notification: Notification) {
    AppEventManager.stop()
  }
}

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.setActivationPolicy(NSApplication.ActivationPolicy.accessory)
NSApplication.shared.run()
