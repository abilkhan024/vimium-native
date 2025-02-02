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
        // if let roleString = role as? String, isInteractiveRole(roleString) {
        //   interactiveElements.append(child)
        // }
        interactiveElements.append(child)
        // Recursively gather interactive elements
        interactiveElements.append(contentsOf: gatherInteractiveElements(from: child))
      }

      return interactiveElements
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

  func exec() -> HintsView? {
    guard let current = (NSWorkspace.shared.frontmostApplication)
    else {
      print("No current application running")
      return nil
    }

    return HintsView(
      els: Array(fetchInteractiveElements(for: current).prefix(169)),
      getPoint: self.getPoint,
      toString: self.toString
    )
  }
}
