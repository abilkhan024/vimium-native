import Cocoa
import Foundation

@MainActor
final class AppCommands {
  static let shared = AppCommands()
  private init() {}

  func daemonize() {
    var pid: pid_t = 0
    let path = "/usr/bin/nohup"
    let args: [String] = ["nohup", CommandLine.arguments[0]]
    var cArgs = args.map { e in strdup(e) } + [nil]

    let status = posix_spawn(&pid, path, nil, nil, &cArgs, nil)
    cArgs.forEach { e in free(e) }

    if status == 0 {
      print("Daemon started with PID: \(pid)")
      exit(0)
    } else {
      print("Failed to spawn daemon")
      exit(1)
    }
  }

  func kill() {
    let app = CommandLine.arguments[0]
    let result = Process()
    result.launchPath = "/usr/bin/killall"
    result.arguments = [URL(fileURLWithPath: app).lastPathComponent]
    try? result.run()
    result.waitUntilExit()
    exit(0)
  }

  func runMenu() {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    statusItem.button?.title = "𝑽𝑰"

    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApp.terminate), keyEquivalent: "q"))
    statusItem.menu = menu
    app.run()
  }

  func run() {
    if CommandLine.arguments.contains("kill") {
      kill()
    } else if CommandLine.arguments.contains("daemon") {
      daemonize()
    } else {
      runMenu()
    }
  }
}
