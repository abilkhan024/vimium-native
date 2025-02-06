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

    var wins: CFTypeRef?
    let winResult = AXUIElementCopyAttributeValue(
      appElement, kAXWindowsAttribute as CFString, &wins)

    guard winResult == .success, let windowsArray = wins as? [AXUIElement] else {
      print(
        "Failed to get windows for application: \(runningApp.localizedName ?? "Unknown App"), with \(winResult)"
      )
      return []
    }

    // TODO: temporarily all, but later select those that are visisble
    var result: [AXUIElement] = []
    for window in windowsArray {
      result.append(contentsOf: dfs(from: window))
    }

    return result
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
