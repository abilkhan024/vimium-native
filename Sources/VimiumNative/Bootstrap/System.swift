import Cocoa

@MainActor
public class System {
  public func pipeOutput() {
    let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
    let logFile = homeDirectory.appendingPathComponent("\(AppInfo.name).log")
    freopen(logFile.path, "a+", stderr)
    freopen(logFile.path, "a+", stdout)
    setbuf(stdout, nil)
    setbuf(stderr, nil)
  }

  public func attachMenu(quit: Selector) {
    let mainMenu = NSMenu()

    // Don't know why TF we need file, but without it it doesn't work
    let fileMenu = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
    let fileSubMenu = NSMenu()
    fileMenu.submenu = fileSubMenu

    fileSubMenu.addItem(NSMenuItem(title: "Quit", action: quit, keyEquivalent: "q"))
    mainMenu.addItem(fileMenu)

    NSApplication.shared.mainMenu = mainMenu
  }

  public func die() {
    NSApplication.shared.terminate(nil)
  }
}
