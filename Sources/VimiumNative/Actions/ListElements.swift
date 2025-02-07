import ApplicationServices
import Cocoa
import SwiftUI

@MainActor
class ListElementsAction {
  func fetchInteractiveElements(for runningApp: NSRunningApplication) -> [AXUIElement] {
    guard let pid = runningApp.processIdentifier as pid_t? else {
      print(
        "Invalid process identifier for application: \(runningApp.localizedName ?? "Unknown App")")
      return []
    }

    let appElement = AXUIElementCreateApplication(pid)

    var cfWindows: CFTypeRef?
    let winResult = AXUIElementCopyAttributeValue(
      appElement, kAXWindowsAttribute as CFString, &cfWindows)

    guard winResult == .success, let windows = cfWindows as? [AXUIElement] else {
      print(
        "Failed to get windows for application: \(runningApp.localizedName ?? "Unknown App"), with \(winResult)"
      )
      return []
    }

    guard let window = windows.first else {
      return []
    }
    return dfs(from: window)
  }

  private func dfs(from element: AXUIElement) -> [AXUIElement] {
    var els: [AXUIElement] = []

    var children: CFTypeRef?
    let childResult = AXUIElementCopyAttributeValue(
      element, kAXChildrenAttribute as CFString, &children)
    guard childResult == .success, let childrenArray = children as? [AXUIElement] else {
      return els
    }

    for child in childrenArray {
      var role: CFTypeRef?
      AXUIElementCopyAttributeValue(child, kAXRoleAttribute as CFString, &role)
      els.append(child)
      els.append(contentsOf: dfs(from: child))
    }

    return els
  }

  func exec() -> [AXUIElement]? {
    guard let current = (NSWorkspace.shared.frontmostApplication)
    else {
      print("No current application running")
      return nil
    }

    return fetchInteractiveElements(for: current)
  }
}
