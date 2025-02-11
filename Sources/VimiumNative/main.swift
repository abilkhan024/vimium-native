import Cocoa

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
  var observer: AxObserver?

  override init() {
    super.init()
    AppEventManager.add(FzFindListener())
    AppEventManager.add(GridListener())
    if let app = NSRunningApplication.runningApplications(withBundleIdentifier: "com.google.Chrome")
      .first
    {
      self.observer = AxObserver(pid: app.processIdentifier)
      let appEl = AXUIElementCreateApplication(app.processIdentifier)

      observer?.addNotification("AXCreated" as CFString, forElement: appEl)
      observer?.addNotification("AXMoved" as CFString, forElement: appEl)
      observer?.addNotification("AXValueChanged" as CFString, forElement: appEl)
      observer?.addNotification("AXTitleChanged" as CFString, forElement: appEl)

      // observer.addNotification(.layoutChanged, forElement: app)
      // observer.addNotification(.valueChanged, forElement: app)
      // observer.addNotification(.selectedChildrenMoved, forElement: app)
      // observer.addNotification(.titleChanged, forElement: app)
      // observer.addNotification(.uiElementDestroyed, forElement: app)
    } else {
      print("Fail")
    }
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
