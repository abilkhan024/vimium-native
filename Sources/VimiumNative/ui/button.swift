import Cocoa

@MainActor
public class Button {
    var action: Selector? = nil;

    public func onClick(_ cb: Selector) -> Button {
        action = cb;
        return self;
    }

    public func make() -> NSButton {
        let button = NSButton(frame: NSMakeRect(150, 120, 100, 40));
        button.title = "Click Me";
        button.bezelStyle = .rounded;
        button.target = self;
        if action != nil {
            button.action = action;
        }
        return button;
    };
}
