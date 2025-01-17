import Cocoa
import CoreGraphics
import Foundation
import ApplicationServices
import SwiftUI

class MyView: NSView {
    public var red: Double = 0; 

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect);
        NSColor(red: red, green: 0.0, blue: 0.0, alpha: 1.0).setFill()
        print("Supposed to be red btw")
        dirtyRect.fill();
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    let window = NSWindow(
            contentRect: NSMakeRect(0, 0, 1920, 1080),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
            );
    let rootView = MyView();

    func applicationDidFinishLaunching(_ notification: Notification) {
        setup();

        // window.contentView?.addSubview(rootView);

        let swiftUIView = Text("Hello from SwiftUI")
            .foregroundColor(.blue)
            .frame(width: 200, height: 20);
        let hostingView = NSHostingView(rootView: swiftUIView);
        hostingView.frame = NSRect(x: 0, y: 0, width: 200, height: 50)
        window.contentView?.addSubview(hostingView);
        // // Create the TextView
        // let textContainer = NSTextContainer(size: NSSize(width: 300, height: 200))
        // let layoutManager = NSLayoutManager()
        // layoutManager.addTextContainer(textContainer)
        // 
        // // Initialize the textView with the layoutManager
        // let textView = NSTextView(frame: NSRect(x: 50, y: 50, width: 300, height: 200), textContainer: textContainer);
        // let attributes: [NSAttributedString.Key: Any] = [
        //     .foregroundColor: NSColor.red
        // ]
        // 
        // // Apply the attributes to the entire text
        // let attributedString = NSAttributedString(string: textView.string, attributes: attributes)
        // textView.textStorage?.setAttributedString(attributedString)
        // textView.font = NSFont.systemFont(ofSize: 14)
        // textView.string = "Hello, this is some sample text!"
        // 
        // // Make the text view editable
        // textView.isEditable = true
        // 
        // // Add the TextView to the view
        // rootView.addSubview(textView)
        // 
        // print("Post");
    }

    @objc func buttonClicked() {
        print("Clicked");
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    private func setup() {
        AppBootstrap.pipeOutput();
        print("Finished launching");
        window.title = AppInfo.name;
        window.makeKeyAndOrderFront(nil);
        NSApplication.shared.mainMenu = AppBootstrap.makeMenu();
    }


    private func findInteractiveElements(in element: AXUIElement, results: inout [AXUIElement]) {
        var children: CFTypeRef?;
        let result = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &children);

        if result == .success, let childrenArray = children as? [AXUIElement] {
            for child in childrenArray {
                var role: CFTypeRef?;
                let roleResult = AXUIElementCopyAttributeValue(child, kAXRoleAttribute as CFString, &role);

                if roleResult == .success, let role = role as? String {
                    if ["AXButton", "AXTextField", "AXCheckBox", "AXRadioButton", "AXPopUpButton", "AXMenuItem"].contains(role) {
                        results.append(child);
                    }
                }
                findInteractiveElements(in: child, results: &results);
            }
        }
    }

    // private func getAllInteractiveElements() {
    //     guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
    //         print("No frontmost application found.");
    //         return;
    //     }
    //
    //     let appPID = frontmostApp.processIdentifier;
    //     let appElement = AXUIElementCreateApplication(appPID);
    //     var interactiveElements = [AXUIElement]();
    //     findInteractiveElements(in: appElement, results: &interactiveElements);
    //     // paintLabels(interactiveElements);
    //
    //     // print("Found \(interactiveElements.count) interactive elements:");
    //     for element in interactiveElements {
    //         var position: AnyObject?;
    //         AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &position);
    //         // print("\(String(describing: position))");
    //         if let pos = position as? CGPoint {
    //             let rect = MyView(frame: CGRect(x: pos.x, y: pos.y, width: 10, height: 10));
    //             window.contentView?.addSubview(rect);
    //             print("Added");
    //         } else {
    //             let rect = MyView(
    //             frame: CGRect(
    //                 x: position?.x ?? 0,
    //                 y: position?.y ?? 0,
    //                 width: 10,
    //                 height: 10
    //             )
    //             );
    //             rootView.addSubview(rect);
    //             print("Pos failed");
    //         }
    //     }
    // }
}


let app = NSApplication.shared;
let delegate = AppDelegate();
app.delegate = delegate;
app.run();
