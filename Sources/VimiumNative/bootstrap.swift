import Cocoa;

public class AppBootstrap {
    public static func Menu() -> NSMenu {
        let mainMenu = NSMenu();

        let appMenuItem = NSMenuItem();
        mainMenu.addItem(appMenuItem);

        let appMenu = NSMenu();
        let quitMenuItem = NSMenuItem(title: "Quit My macOS App",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q");
        quitMenuItem.keyEquivalentModifierMask = [.command];
        appMenu.addItem(quitMenuItem);
        appMenuItem.submenu = appMenu;

        return mainMenu;
    }

    public static func pipeOutput() -> Void {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser;
        let logFile = homeDirectory.appendingPathComponent("\(AppInfo.name).log");
        freopen(logFile.path, "a+", stderr); // Redirect stderr to the log file
        freopen(logFile.path, "a+", stdout); // Redirect stdout to the log file
    }

    public static func makeMenu() -> NSMenu {
        let menu = NSMenu();
        let appMenuItem = NSMenuItem();
        menu.addItem(appMenuItem);

        let appMenu = NSMenu();
        let quitMenuItem = NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenu.addItem(quitMenuItem);
        appMenuItem.submenu = appMenu;
        return menu;
    }
}
