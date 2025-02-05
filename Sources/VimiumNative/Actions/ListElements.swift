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

  private func getAttributeString(_ el: AXUIElement, _ attribute: String) -> String? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(el, attribute as CFString, &value)
    guard result == .success, let stringValue = value as? String else {
      return nil
    }
    return stringValue
  }

  private func asString(_ el: AXUIElement) -> String? {
    let components = [
      // getAttributeString(el, kAXRoleAttribute) ?? "",
      // getAttributeString(el, kAXTitleAttribute) ?? "",
      getAttributeString(el, kAXValueAttribute) ?? "",
      // getAttributeString(el, kAXDescriptionAttribute) ?? "",
      // getAttributeString(el, kAXLabelValueAttribute) ?? "",
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

  func exec() -> HintsView? {
    guard let current = (NSWorkspace.shared.frontmostApplication)
    else {
      print("No current application running")
      return nil
    }

    let els = fetchInteractiveElements(for: current)
    print("Count \(els.count)")
    return HintsView(
      els: els,
      getPoint: self.getPoint,
      toString: self.asString
    )
  }
}
