import Cocoa

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
  var badge: TrayBadge?
  let window = RootWindow()
  let system = System()
  let appView = AppView()

  func applicationDidFinishLaunching(_ notification: Notification) {
    system.pipeOutput()
    system.attachMenu(quit: #selector(quit), close: #selector(close))
    if !AXIsProcessTrusted() {
      runTask(
        path: "/usr/bin/tccutil",
        args: ["reset", "Accessibility", "com.example.VimiumNative"]
      ).waitUntilExit()
      openA11y()
      return system.die()
    }

    badge = TrayBadge(onOpen: #selector(open), onQuit: #selector(quit))
    window.open(view: appView)
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

  @objc private func close() { window.close() }
  @objc private func open() { window.open(view: appView) }
  @objc private func quit() { system.die() }
}

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
