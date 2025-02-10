import Cocoa

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {

  override init() {
    super.init()
    AppEventManager.add(FzFindListener())
    AppEventManager.add(GridListener())
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    if !AXIsProcessTrusted() {
      return print("AXIsProcessTrusted is false")
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
NSApplication.shared.run()
