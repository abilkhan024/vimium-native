import Cocoa

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {

  override init() {
    super.init()
    AppEventManager.add(HintListener())
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    if !AXIsProcessTrusted() {
      return print("AXIsProcessTrusted is false")
    }
    AppEventManager.listen()
    print("Started")
  }

  func applicationWillTerminate(_ notification: Notification) {
    AppEventManager.stop()
  }
}

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
