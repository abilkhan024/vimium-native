import Cocoa

@MainActor
public class Button {
    public func make() -> NSButton {
        let button = NSButton(frame: NSMakeRect(150, 120, 100, 40));
        button.title = "Click Me";
        button.bezelStyle = .rounded;
        button.target = self;
        button.action = #selector(buttonClicked);
        return button;
    };

    @objc func buttonClicked() {
        print("Clicked");
    }
};
