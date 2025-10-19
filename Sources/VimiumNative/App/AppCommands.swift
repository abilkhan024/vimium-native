import Cocoa
import Foundation

@MainActor
final class AppCommands {
  static let shared = AppCommands()

  let appBin = CommandLine.arguments[0]
  let fs = FileManager.default

  enum Action: String {
    case daemon = "daemon"
    case kill = "kill"
    case listFonts = "list-fonts"
  }

  private init() {}

  func daemonize() {
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

  func findProcesses(path target: String) -> [pid_t] {
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
    var size = 0

    if sysctl(&mib, u_int(mib.count), nil, &size, nil, 0) != 0 {
      return []
    }

    let count = size / MemoryLayout<kinfo_proc>.stride
    let buffer = UnsafeMutablePointer<kinfo_proc>.allocate(capacity: count)

    defer { buffer.deallocate() }

    if sysctl(&mib, u_int(mib.count), buffer, &size, nil, 0) != 0 {
      return []
    }

    var result: [pid_t] = []

    for i in 0..<count {
      let proc = buffer[i].kp_proc
      let path = getPath(pid: proc.p_pid)

      if path == target {
        result.append(proc.p_pid)
      }
    }

    return result
  }

  func getPath(pid: pid_t) -> String? {
    var buf = [CChar](repeating: 0, count: Int(PATH_MAX))
    let ret = proc_pidpath(pid, &buf, UInt32(buf.count))
    if ret > 0 {
      return String(utf8String: buf)
    }
    return nil
  }

  func killRunning() -> Bool {
    let currentPid = getpid()
    guard let currentPath = getPath(pid: currentPid) else {
      print("Impossible case: couldn't resolve exec file path")
      return false
    }
    var killedSomePid = false
    for pid in findProcesses(path: currentPath) {
      if pid != currentPid {
        killedSomePid = true
        kill(pid, SIGKILL)
      }
    }

    return killedSomePid
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
