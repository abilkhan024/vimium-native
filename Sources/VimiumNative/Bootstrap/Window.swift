import ApplicationServices
import Cocoa
import SwiftUI

@MainActor
class Window {
  private var window = NSWindow(
    contentRect: NSMakeRect(0, 0, 0, 0),
    styleMask: [.titled, .closable, .resizable],
    backing: .buffered,
    defer: false
  )

  private func makeWindow(view: some View) -> NSWindow {
    let window = NSWindow(
      contentRect: NSMakeRect(0, 0, 0, 0),
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )

    if let screen = NSScreen.main {
      let screenFrame = screen.frame
      window.setFrame(screenFrame, display: true)
    }
    window.isOpaque = false
    window.backgroundColor = .clear
    window.level = .floating
    window.ignoresMouseEvents = true
    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

    let hostingView = NSHostingView(rootView: view)
    hostingView.frame = NSRect(
      x: 0,
      y: 0,
      width: window.frame.width,
      height: window.frame.height
    )
    window.contentView?.addSubview(hostingView)
    print("Render")
    window.makeKeyAndOrderFront(nil)
    return window
  }

  public func open(view: some View) {
    window.title = AppInfo.name

    if let screen = NSScreen.main {
      let screenFrame = screen.frame
      window.setFrame(screenFrame, display: true)
    }

    let hostingView = NSHostingView(rootView: view)
    hostingView.frame = NSRect(
      x: 0,
      y: 0,
      width: window.frame.width,
      height: window.frame.height
    )
    window.contentView?.subviews.removeAll()
    window.contentView?.addSubview(hostingView)
    window.makeKeyAndOrderFront(nil)
  }

  func close() {
    window.close()

    window = NSWindow(
      contentRect: NSMakeRect(0, 0, 0, 0),
      styleMask: [.titled, .closable, .resizable],
      backing: .buffered,
      defer: false
    )
  }

  private func renderOnTop(point: CGPoint, content: String) {
    let _ = makeWindow(
      view: Text(content).position(x: point.x, y: point.y).onAppear(perform: {
        print("Appear")
      }).foregroundColor(.red))
  }

  func fetchInteractiveElements(for runningApp: NSRunningApplication) -> [AXUIElement] {
    guard let pid = runningApp.processIdentifier as pid_t? else {
      print(
        "Invalid process identifier for application: \(runningApp.localizedName ?? "Unknown App")")
      return []
    }

    // Create the accessibility object for the application
    let appElement = AXUIElementCreateApplication(pid)

    // Get all windows of the application
    var windows: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(
      appElement, kAXWindowsAttribute as CFString, &windows)

    guard result == .success, let windowsArray = windows as? [AXUIElement] else {
      print(
        "Failed to get windows for application: \(runningApp.localizedName ?? "Unknown App"), with result \(result)"
      )
      return []
    }

    // Function to recursively gather interactive elements
    func gatherInteractiveElements(from element: AXUIElement) -> [AXUIElement] {
      var interactiveElements: [AXUIElement] = []

      // Get child elements
      var children: CFTypeRef?
      let childResult = AXUIElementCopyAttributeValue(
        element, kAXChildrenAttribute as CFString, &children)
      guard childResult == .success, let childrenArray = children as? [AXUIElement] else {
        return interactiveElements
      }

      // Traverse children and filter by role
      for child in childrenArray {
        var role: CFTypeRef?
        AXUIElementCopyAttributeValue(child, kAXRoleAttribute as CFString, &role)
        if let roleString = role as? String, isInteractiveRole(roleString) {
          interactiveElements.append(child)
        }
        // Recursively gather interactive elements
        interactiveElements.append(contentsOf: gatherInteractiveElements(from: child))
      }

      return interactiveElements
    }

    // Helper to determine if an element is interactive
    func isInteractiveRole(_ role: String) -> Bool {
      let interactiveRoles = [
        kAXButtonRole,
        kAXTextFieldRole,
        kAXCheckBoxRole,
        kAXRadioButtonRole,
        kAXMenuItemRole,
        kAXSliderRole,
        kAXPopUpButtonRole,
      ]
      return interactiveRoles.contains(role)
    }

    // Collect interactive elements from all windows
    var allInteractiveElements: [AXUIElement] = []
    for window in windowsArray {
      allInteractiveElements.append(contentsOf: gatherInteractiveElements(from: window))
    }

    return allInteractiveElements
  }

  private func toString(el: AXUIElement) -> String? {
    func getAttributeString(_ attribute: String) -> String? {
      var value: CFTypeRef?
      let result = AXUIElementCopyAttributeValue(el, attribute as CFString, &value)
      guard result == .success, let stringValue = value as? String else {
        return nil
      }
      return stringValue
    }

    let components = [
      getAttributeString(kAXRoleAttribute) ?? "",
      getAttributeString(kAXTitleAttribute) ?? "",
      getAttributeString(kAXDescriptionAttribute) ?? "",
      getAttributeString(kAXLabelValueAttribute) ?? "",
    ].filter { !$0.isEmpty }
    return components.isEmpty ? nil : components.joined(separator: ", ")
  }

  private func getPoint(el: AXUIElement) -> CGPoint? {
    var position: CFTypeRef?

    // Try to fetch the position of the element
    let result = AXUIElementCopyAttributeValue(el, kAXPositionAttribute as CFString, &position)
    guard result == .success else {
      print("Failed to get position for element: \(el)")
      return nil
    }
    let positionValue = (position as! AXValue)

    // Convert AXValue to CGPoint
    var point = CGPoint.zero
    let success = AXValueGetValue(positionValue, .cgPoint, &point)
    return success ? point : nil
  }

  func listAll() {
    guard
      let chrome =
        (NSWorkspace.shared.frontmostApplication
          ?? NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == "com.google.Chrome.helper.plugin"
          }.first)
    else {
      return
    }
    // for app in NSWorkspace.shared.runningApplications {
    // print("\(app.description) \(app.bundleIdentifier)")
    // }

    // print("Trusted \(AXIsProcessTrusted())")
    //
    // if !AXIsProcessTrusted() {
    //   NSWorkspace.shared.open(
    //     URL(
    //       string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    // }

    for el in fetchInteractiveElements(for: chrome) {
      if let point = getPoint(el: el), let content = toString(el: el) {
        renderOnTop(point: point, content: content)
      }
      // print(
      //   "\((toString(el: el) ?? "Unkown")) \(el), x \(getPoint(el: el)?.x ?? -1), y \(getPoint(el: el)?.y ?? -1)"
      // )
    }

    // print("App: \(app)")
    // guard let frontAppPID = NSWorkspace.shared.frontmostApplication?.processIdentifier else {
    //   return
    // }
    // let appElement = AXUIElementCreateApplication(frontAppPID)
    //
    // var frontWindow: AXUIElement?
    // var value: AnyObject?
    //
    // // Get the front-most window of the application
    // if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &value)
    //   == .success
    // {
    //   frontWindow = (value as! AXUIElement)
    // }
    //
    // // Get all UI elements (interactive elements) in the window
    // var elements: CFTypeRef?
    // if AXUIElementCopyAttributeValue(frontWindow!, kAXChildrenAttribute as CFString, &elements)
    //   == .success
    // {
    //   guard let elementsArray = elements as? [AXUIElement] else { return }
    //
    //   for element in elementsArray {
    //
    //     var position: CFTypeRef?
    //     var role: CFTypeRef?
    //
    //     if AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &position)
    //       == .success
    //       && AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
    //         == .success
    //     {
    //       let point = (position as! AXValue)
    //       var x: CGFloat = 0
    //       var y: CGFloat = 0
    //       AXValueGetValue(point, .cgPoint, &x)
    //       AXValueGetValue(point, .cgPoint, &y)
    //       // , label \(role as? String ?? "Unknown")
    //       print("Element \(element), position: (\(x), \(y))")
    //     }
    //   }
    //   //   var roleValue: CFTypeRef?
    //   //   if AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)
    //   //     == .success,
    //   //     let role = roleValue as? String
    //   //   {
    //   //     if role == "AXButton" {
    //   //       print("Button Found")
    //   //     } else if role == "AXTextField" {
    //   //       print("Text Field Found")
    //   //     }
    //   //   }
    //   // }
  }
}
