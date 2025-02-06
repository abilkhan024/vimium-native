import ApplicationServices
import Cocoa
import SwiftUI

class AXUIElementUtils {
  static func toString(_ el: AXUIElement) -> String? {
    let components = [
      // getAttributeString(el, kAXRoleAttribute) ?? "",
      // getAttributeString(el, kAXTitleAttribute) ?? "",
      AXUIElementUtils.getAttributeString(el, kAXValueAttribute) ?? ""
        // getAttributeString(el, kAXDescriptionAttribute) ?? "",
        // getAttributeString(el, kAXLabelValueAttribute) ?? "",
    ].filter { !$0.isEmpty }
    return components.isEmpty ? nil : components.joined(separator: ", ")
  }

  static func getPoint(_ el: AXUIElement) -> CGPoint? {
    var position: CFTypeRef?

    let result = AXUIElementCopyAttributeValue(el, kAXPositionAttribute as CFString, &position)
    guard result == .success else {
      return nil
    }
    let positionValue = (position as! AXValue)

    var point = CGPoint.zero
    let success = AXValueGetValue(positionValue, .cgPoint, &point)
    return success ? point : nil
  }

  static func getSize(_ el: AXUIElement) -> CGSize? {
    var value: AnyObject?
    let result = AXUIElementCopyAttributeValue(el, kAXSizeAttribute as CFString, &value)

    if result == .success, let sizeValue = value as! AXValue? {
      var size: CGSize = .zero
      if AXValueGetType(sizeValue) == .cgSize {
        AXValueGetValue(sizeValue, .cgSize, &size)
        return size
      }
    }
    return nil
  }

  static func getAttributeString(_ el: AXUIElement, _ attribute: String) -> String? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(el, attribute as CFString, &value)
    guard result == .success, let stringValue = value as? String else {
      return nil
    }
    return stringValue
  }

  static func isInViewport(_ element: AXUIElement) -> Bool? {
    var value: AnyObject?
    let result = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &value)

    guard result == .success, let positionValue = value as! AXValue? else {
      return nil
    }

    var position = CGPoint.zero
    if AXValueGetType(positionValue) == .cgPoint {
      AXValueGetValue(positionValue, .cgPoint, &position)
    }

    var sizeValue: AnyObject?
    let sizeResult = AXUIElementCopyAttributeValue(
      element, kAXSizeAttribute as CFString, &sizeValue)

    guard sizeResult == .success, let sizeAXValue = sizeValue as! AXValue? else {
      return nil
    }

    var size = CGSize.zero
    if AXValueGetType(sizeAXValue) == .cgSize {
      AXValueGetValue(sizeAXValue, .cgSize, &size)
    }

    let screenBounds = NSScreen.main?.frame ?? NSRect.zero

    let elementRect = CGRect(origin: position, size: size)
    return screenBounds.intersects(elementRect)
  }
}
