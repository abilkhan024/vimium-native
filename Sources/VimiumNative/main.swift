import Cocoa

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
  var badge: TrayBadge?
  let window = Window()
  let system = System()
  var view = SettingsView(onMount: {})

  func applicationDidFinishLaunching(_ notification: Notification) {
    system.pipeOutput()
    view = SettingsView(onMount: window.listAll)
    system.attachMenu(quit: #selector(quit), close: #selector(close))
    badge = TrayBadge(onOpen: #selector(open), onQuit: #selector(quit))
    window.open(view: view)
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
