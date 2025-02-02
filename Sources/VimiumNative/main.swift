import Cocoa

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
  var badge: TrayBadge?
  let window = Window()
  let system = System()
  var view = SettingsView(action: {})

  func applicationDidFinishLaunching(_ notification: Notification) {
    system.pipeOutput()
    view = SettingsView(action: window.listAll)
    system.attachMenu(quit: #selector(quit), close: #selector(close))
    if !AXIsProcessTrusted() {
      runTask(
        path: "/usr/bin/tccutil",
        args: ["reset", "Accessibility", "com.example.VimiumNative"]
      ).waitUntilExit()
      openA11y()
    } else {
      NSEvent.addGlobalMonitorForEvents(
        matching: .keyDown,
        handler: { (event) in
          if !event.modifierFlags.contains([.command, .shift]) || event.keyCode != 47 {
            return
          }
          self.window.listAll()
        })
    }
    badge = TrayBadge(onOpen: #selector(open), onQuit: #selector(quit))
    window.open(view: view)
  }

  func runTask(path: String, args: [String]?) -> Process {
    let task = Process()
    task.launchPath = path
    task.arguments = args
    task.launch()
    return task
  }

  func openA11y() {
    let url = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    NSWorkspace.shared.open(URL(string: url)!)
  }

  func applicationDidBecomeActive(_ notification: Notification) {
    print("Did")
    window.open(view: view)
  }

  func applicationWillResignActive(_ notification: Notification) {
    print("Resign")
  }

  @objc private func close() { window.close() }
  @objc private func open() { window.open(view: view) }
  @objc private func quit() { system.die() }
}

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
