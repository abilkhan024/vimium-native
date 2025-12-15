import Cocoa
import Foundation

private extension String {
  static let daemonName = "vimium-native"
  static let daemonPackageName = "io.github.abilkhan024.\(daemonName)"
}

@MainActor
final class AppCommands {
  static let shared = AppCommands()

  let appBin = CommandLine.arguments[0]
  let fs = FileManager.default
  private let isForeground = CommandLine.arguments.count == 1

  // TODO: move to cli assembly
  private var daemon: IDaemon {
    Daemon(name: .daemonName, packageName: .daemonPackageName)
  }

  enum Action: String {
    case startDaemon = "start-daemon"
    case stopDaemon = "stop-daemon"
    case restartDaemon = "restart-daemon"
    case listFonts = "list-fonts"
    case listLayouts = "list-layouts"

    var needsConfig: Bool {
      switch self {
      case .startDaemon, .stopDaemon, .restartDaemon: true
      default: false
      }
    }
  }

  private init() {}

  func getConfigNeeded() -> Bool {
    if isForeground { return true }
    let command = CommandLine.arguments[1]
    return Action(rawValue: command)?.needsConfig ?? false
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

  @objc private func editConfig() {
    NSWorkspace.shared.open(URL(fileURLWithPath: AppOptions.shared.getConfigPath().path))
  }

  private func setupAndRun() {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)

    if AppOptions.shared.showMenuItem {
      let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
      statusItem.button?.title = "𝑽𝑰"

      let menu = NSMenu()
      let editConfgItem = NSMenuItem(
        title: "Edit config",
        action: #selector(editConfig),
        keyEquivalent: ""
      )
      editConfgItem.target = self
      menu.addItem(editConfgItem)

      menu.addItem(
        NSMenuItem(
          title: "Quit",
          action: #selector(NSApp.terminate),
          keyEquivalent: ""
        )
      )
      statusItem.menu = menu
    }
    app.run()
  }

  private func showHelp(entered: String) {
    print(
      """

        What do you mean by '\(entered)'?

        May be you want to:

            vimium start-daemon - Run as a persistent daemon
            vimium stop-daemon - Stop running daemon
            vimium restart-daemon - Restart daemon (if any)
            vimium kill - Kill process running daemon mode
            vimium list-fonts - List avaible fonts on the system
            vimium list-layouts - List avaible keyboard layouts on the system
            vimium - Run in foreground

      """)
  }

  func run() {
    if isForeground { return setupAndRun() }

    let command = CommandLine.arguments[1]
    guard let action = Action(rawValue: command)
    else { return showHelp(entered: command) }

    var status: Int32 = 0
    defer { exit(status) }

    switch action {
    case .listLayouts:
      listLayouts()
    case .listFonts:
      listFonts()
    case .startDaemon:
      do {
        try daemon.start()
      } catch {
        status = 1
        print("Unable to start daemon")
        print(error.localizedDescription)
      }
    case .stopDaemon:
      do {
        try daemon.stop()
      } catch {
        status = 1
        print("Unable to stop daemon")
        print(error.localizedDescription)
      }
    case .restartDaemon:
      do {
        try daemon.restart()
      } catch {
        status = 1
        print("Unable to restart daemon")
        print(error.localizedDescription)
      }
    }
  }
}
