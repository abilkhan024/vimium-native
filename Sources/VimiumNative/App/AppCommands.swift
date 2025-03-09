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
    case listFonts = "list-fonts"
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
      print("Started in daemon mode, PID: \(p.processIdentifier)")
    } catch {
      print("Failed to write daemon pid, terminating")
      p.terminate()
    }
  }

  func listFonts() {
    for font in NSFontManager.shared.availableFontFamilies {
      if let members = NSFontManager.shared.availableMembers(ofFontFamily: font) {
        for member in members {
          print(member[0])
        }
      }
    }
  }

  func getConfigNeeded() -> Bool {
    if CommandLine.arguments.count == 1 {
      return true
    }
    let command = CommandLine.arguments[1]
    switch command {
    case Action.daemon.rawValue:
      return true
    default:
      return false
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

  func showHelp(entered: String) {
    print(
      """

        What do you mean by '\(entered)'?

        May be you want to:

            vimium daemon - Run in daemon mode
            vimium kill - Kill process running daemon mode
            vimium list-fonts - List avaible fonts on the system
            vimium - Run in foreground

      """)
  }

  func run() {
    if CommandLine.arguments.count == 1 {
      return runMenu()
    }
    let command = CommandLine.arguments[1]
    switch command {
    case Action.kill.rawValue:
      if !killRunning() {
        print("Didn't find any daemons")
      }
      exit(0)
    case Action.listFonts.rawValue:
      listFonts()
      exit(0)
    case Action.daemon.rawValue:
      let _ = killRunning()
      daemonize()
      exit(0)
    default:
      showHelp(entered: command)
    }
  }
}
