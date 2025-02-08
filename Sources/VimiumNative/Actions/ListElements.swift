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
    guard let current = (NSWorkspace.shared.frontmostApplication)
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
