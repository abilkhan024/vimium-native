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
      if let role = AxElementUtils.getAttributeString(el, kAXRoleAttribute), role == "AXWindow" {
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

  let test = [
    "AXButton",
    "AXLink",
  ]
  private func dfs(from element: AXUIElement) -> [AXUIElement] {
    if let role = AxElementUtils.getAttributeString(element, kAXRoleAttribute), test.contains(role)
    {
      return []
    }
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
    return []
  }

  func exec() -> [AXUIElement]? {
    guard let app = NSWorkspace.shared.frontmostApplication
    else {
      print("No current application running")
      return nil
    }

    return getInteractiveElements(for: app)
  }
}
