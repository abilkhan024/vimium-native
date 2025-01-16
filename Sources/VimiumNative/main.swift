import Cocoa

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    let window = NSWindow(
            contentRect: NSMakeRect(0, 0, 1920, 1080),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
            );

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppBootstrap.pipeOutput();
        // Print is not immidieate
        print("Finished launching");
        window.title = AppInfo.name;
        window.makeKeyAndOrderFront(nil);
        NSApplication.shared.mainMenu = AppBootstrap.makeMenu();

        // let button = NSButton(frame: NSMakeRect(150, 120, 100, 40));
        // button.title = "Click Me";
        // button.bezelStyle = .rounded;
        // button.target = self;
        // button.action = #selector(buttonClicked);
        let button = Button().make();
        window.contentView?.addSubview(button);
    }

    // @objc func buttonClicked() {
    //     print("Clicked");
    // }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}


let app = NSApplication.shared;
let delegate = AppDelegate();
app.delegate = delegate;
app.run();
