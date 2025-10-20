import Cocoa
import Foundation

@MainActor
final class AppCommands {
  static let shared = AppCommands()

  let appBin = CommandLine.arguments[0]
  let fs = FileManager.default
  private let isForeground = CommandLine.arguments.count == 1

  enum Action: String {
    case daemon = "daemon"
    case kill = "kill"
    case listFonts = "list-fonts"
    case listLayouts = "list-layouts"
  }

  private init() {}

  func getConfigNeeded() -> Bool {
    if isForeground {
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

  private func daemonize() {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    p.arguments = [appBin]
    do {
      try p.run()
      print("Started in daemon mode, PID: \(p.processIdentifier)")
    } catch let error {
      print("Failed with error \(error), terminating...")
      p.terminate()
    }
  }

  private func listFonts() {
    for font in NSFontManager.shared.availableFontFamilies {
      if let members = NSFontManager.shared.availableMembers(ofFontFamily: font) {
        for member in members {
          print(member[0])
        }
      }
    }
  }

  private func listLayouts() {
    for src in InputSourceUtils.getAllInputSources() {
      print(InputSourceUtils.getInputSourceId(src: src))
    }
  }

  private func exitAfter(_ after: () -> Void) {
    after()
    exit(0)
  }

  private func killRunning() -> Bool {
    let currentPid = getpid()
    guard let currentPath = ProcessUtils.getPath(pid: currentPid) else {
      print("Impossible case: couldn't resolve exec file path")
      return false
    }
    var killedSomePid = false
    for pid in ProcessUtils.findProcesses(path: currentPath) {
      if pid != currentPid {
        killedSomePid = true
        kill(pid, SIGKILL)
      }
    }

    return killedSomePid
  }

  private func runMenu() {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    statusItem.button?.title = "𝑽𝑰"

    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApp.terminate), keyEquivalent: "q"))
    statusItem.menu = menu
    app.run()
  }

  private func showHelp(entered: String) {
    print(
      """

        What do you mean by '\(entered)'?

        May be you want to:

            vimium daemon - Run in daemon mode
            vimium kill - Kill process running daemon mode
            vimium list-fonts - List avaible fonts on the system
            vimium list-layouts - List avaible keyboard layouts on the system
            vimium - Run in foreground

      """)
  }

  func run() {
    if isForeground {
      return runMenu()
    }
    let command = CommandLine.arguments[1]
    switch command {
    case Action.kill.rawValue:
      exitAfter {
        if !killRunning() { print("Didn't find any daemons") }
      }
    case Action.listLayouts.rawValue:
      exitAfter(listLayouts)
    case Action.listFonts.rawValue:
      exitAfter(listFonts)
    case Action.daemon.rawValue:
      exitAfter {
        let _ = killRunning()
        daemonize()
      }
    default:
      showHelp(entered: command)
    }
  }
}
