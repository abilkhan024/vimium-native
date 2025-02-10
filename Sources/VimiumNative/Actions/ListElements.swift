import ApplicationServices
import Cocoa
import SwiftUI

@MainActor
class ListElementsAction {
  private func getInteractiveElements(for runningApp: NSRunningApplication) -> [AXUIElement] {
    guard let pid = runningApp.processIdentifier as pid_t? else {
      print(
        "Invalid process identifier for application: \(runningApp.localizedName ?? "Unknown App")")
      return []
    }

    let appEl = AXUIElementCreateApplication(pid)

    var cfWindows: CFTypeRef?
    let winResult = AXUIElementCopyAttributeValue(
      appEl, kAXWindowsAttribute as CFString, &cfWindows)

    guard winResult == .success, let windows = cfWindows as? [AXUIElement] else {
      print(
        "Failed to get windows for application: \(runningApp.localizedName ?? "Unknown App"), with \(winResult)"
      )
      return []
    }

    var els: [AXUIElement] = []

    for el in windows {
      els.append(el)
      if let role = AXUIElementUtils.getAttributeString(el, kAXRoleAttribute), role == "AXWindow" {
        break
      }
    }

    var result: [AXUIElement] = []

    for el in els {
      for sub in dfs(from: el) {
        result.append(sub)
      }
    }

    var menuBar: AnyObject?
    let menuResult = AXUIElementCopyAttributeValue(appEl, kAXMenuBarAttribute as CFString, &menuBar)

    if menuResult == .success, let menu = menuBar as! AXUIElement? {
      for el in dfs(from: menu) {
        result.append(el)
      }
    }

    return result
  }

  private func dfs(from element: AXUIElement) -> [AXUIElement] {
    var els: [AXUIElement] = []

    var children: CFTypeRef?
    let childResult = AXUIElementCopyAttributeValue(
      element, kAXChildrenAttribute as CFString, &children)

    if childResult == .success, let childrenEls = children as? [AXUIElement] {
      for child in childrenEls {
        els.append(child)
        els.append(contentsOf: dfs(from: child))
      }
    }

    return els
  }

  private func getSystemEls() -> [AXUIElement] {
    // TODO: May be later, HomeRow must do something different
    // guard
    //   let app = NSRunningApplication.runningApplications(
    //     withBundleIdentifier: "com.apple.systemuiserver"
    //   ).first
    // else { return [] }
    // let appEl = AXUIElementCreateApplication(app.processIdentifier)
    //
    // let sys = AXUIElementCreateSystemWide()
    //
    // func dfs(_ el: AXUIElement) -> AXUIElement? {
    //   var menuBar: AnyObject?
    //   let menuResult = AXUIElementCopyAttributeValue(
    //     el, kAXMenuBarAttribute as CFString, &menuBar)
    //
    //   if menuResult == .success, let menu = menuBar as! AXUIElement? {
    //     return menu
    //   }
    //
    //   var children: CFTypeRef?
    //   let childResult = AXUIElementCopyAttributeValue(
    //     el, kAXChildrenAttribute as CFString, &children)
    //
    //   if childResult == .success, let childrenEls = children as? [AXUIElement] {
    //     for child in childrenEls {
    //       print("Child")
    //       if let menu = dfs(child) {
    //         return menu
    //       }
    //     }
    //   }
    //
    //   return nil
    // }
    //
    // print(dfs(sys))

    // let sysEl = AXUIElementCreateApplication(app.processIdentifier)
    //
    // var menuBar: AnyObject?
    // let menuResult = AXUIElementCopyAttributeValue(sysEl, kAXMenuBarAttribute as CFString, &menuBar)
    //
    // if menuResult == .success, let menuBarElement = menuBar as! AXUIElement? {
    //   print("Successfully accessed SystemUIServer menu bar, \(menuBarElement)")
    // } else {
    //   print("Menu failed with \(menuResult)")
    // }
    //
    // var children: AnyObject?
    // let childrenResult = AXUIElementCopyAttributeValue(
    //   sysEl, kAXChildrenAttribute as CFString, &children)
    //
    // if childrenResult == .success, let childrenEls = children as? [AXUIElement] {
    //   print("Count \(childrenEls.count)")
    // } else {
    //   print("Failed with \(childrenResult)")
    // }

    return []
  }

  func exec() -> [AXUIElement]? {
    guard let current = NSWorkspace.shared.frontmostApplication
    else {
      print("No current application running")
      return nil
    }
    // var all = getSystemEls()
    // for el in getInteractiveElements(for: current) {
    //   all.append(el)
    // }
    return getInteractiveElements(for: current)
  }
}

// class AccessibilityObserver {
//   private var observer: CFRunLoopObserver?
//   private var axObserver: AXObserver?
//   private var targetApplication: pid_t?
//
//   init() {
//     guard
//       let app = NSRunningApplication.runningApplications(withBundleIdentifier: "com.google.Chrome")
//         .first
//     else {
//       print("No chrome app")
//       return
//     }
//     targetApplication = app.processIdentifier
//
//   }
//
//   func startObserving(for application: NSRunningApplication) {
//       targetApplication = application.processIdentifier
//
//       // 1. Create the AXObserver
//       var error: CFError?
//       let observerCallback: AXObserverCallback = { (observer, element, notification, userInfo) in
//           guard let notification = notification as String,
//                 notification == kAXCreatedNotification as String,
//                 let element = element as! AXUIElement else { return } // Safe cast
//
//           self.handleElementCreation(element: element)
//       }
//
//       AXObserverCreateWithInfoCallback(
//           0 as CFAllocator?, // Use default allocator
//           observerCallback,
//           &axObserver,
//           &error
//       )
//
//       if let error = error {
//           print("Error creating AXObserver: \(error)")
//           return
//       }
//
//       guard let axObserver = axObserver else { return }
//
//
//       // 2. Get the Application's AXUIElement
//       let applicationElement = AXUIElementCreateApplication(targetApplication!)
//
//       // 3. Add the notification
//       error = nil
//       AXObserverAddNotification(
//           axObserver,
//           applicationElement,
//           kAXCreatedNotification as CFString,
//           nil
//       )
//
//       if let error = error {
//           print("Error adding notification: \(error)")
//           return
//       }
//
//       // 4. Add the observer to the run loop
//       let runLoopSource = CFRunLoopSourceCreate(
//           kCFAllocatorDefault,
//           0,
//       )
//           // AXObserverGetRunLoopSource(axObserver)
//
//       observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, 0, true, 0) { (observer, activity) in
//           if activity == .entry {
//               CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
//           } else if activity == .exit {
//               CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
//           }
//       }
//
//       if let observer = observer {
//           CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, .commonModes)
//       }
//
//       print("Started observing for kAXCreatedNotification")
//   }
//
//   private func handleElementCreation(element: AXUIElement) {
//       // This is where you'll receive callbacks for newly created elements
//       print("New element created: \(element)")
//
//       //  Get more information about the element (example)
//       var value: AnyObject?
// let err = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &value)
//
//       if err == .success, let role = value as? String {
//           print("Role: \(role)")
//       } else {
//           print("Error getting role: \(err)")
//       }
//
//
//       // ... process the element as needed ...
//   }
//
//
//   func stopObserving() {
//       guard let axObserver = axObserver  else { return }
//         let applicationElement = AXUIElementCreateApplication(targetApplication!)
//
//       AXObserverRemoveNotification(axObserver, applicationElement, kAXCreatedNotification as CFString)
//       CFRunLoopRemoveSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(axObserver), .commonModes)
//       self.axObserver = nil
//       self.observer = nil
//       self.targetApplication = nil
//
//       print("Stopped observing")
//   }
// }
