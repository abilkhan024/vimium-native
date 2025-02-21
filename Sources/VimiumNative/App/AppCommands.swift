import Cocoa
import Foundation

@MainActor
final class AppCommands {
  static let shared = AppCommands()

  let appPath = CommandLine.arguments[0]
  let daemonPath = "/tmp/vimium-native-daemon"
  let daemonLogPath = "/tmp/vimium-native-daemon.log"
  let fs = FileManager.default

  enum Action: String {
    case daemon = "daemon"
    case kill = "kill"
  }

  private init() {}

  func daemonize() {
    let p = Process()
    if !fs.fileExists(atPath: daemonLogPath) {
      fs.createFile(atPath: daemonLogPath, contents: nil, attributes: nil)
    }
    p.standardOutput = FileHandle(forWritingAtPath: daemonLogPath)
    p.standardError = FileHandle(forWritingAtPath: daemonLogPath)
    p.executableURL = URL(fileURLWithPath: appPath)
    try? p.run()
    do {
      try "\(p.processIdentifier)".write(toFile: daemonPath, atomically: true, encoding: .utf8)
      print("Started in daemon mode \(p.processIdentifier)")
    } catch {
      print("Failed to write daemon pid, terminating")
      p.terminate()
    }
  }

  func killRunning() -> Bool {
    do {
      let content = try String(contentsOfFile: daemonPath, encoding: .utf8)
      guard let pid = Int32(content) else {
        print("Impossible case, daemon file doesn't contain valid pid")
        exit(1)
      }
      try fs.removeItem(atPath: daemonLogPath)
      kill(pid, SIGKILL)
      return true
    } catch {
      return false
    }

    // let p = Process()
    // p.launchPath = Deps.killall.rawValue
    // p.processIdentifier
    // let name = URL(fileURLWithPath: appPath).lastPathComponent
    // // p.arguments = ["\"\(name) \(Action.daemon.rawValue)\""]
    // p.arguments = [name]
    // try? p.run()
    // p.waitUntilExit()
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
    if CommandLine.arguments.contains(Action.kill.rawValue) {
      if !killRunning() {
        print("Didn't find any daemons")
      }
      exit(0)
    } else if CommandLine.arguments.contains(Action.daemon.rawValue) {
      let _ = killRunning()
      daemonize()
      exit(0)
    } else {
      runMenu()
    }
  }
}
