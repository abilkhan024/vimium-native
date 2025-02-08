import ApplicationServices
import Cocoa
import SwiftUI

class AXUIElementUtils {
  static func toString(_ el: AXUIElement) -> String? {
    let components = [
      getAttributeString(el, kAXRoleAttribute) ?? "",
      getAttributeString(el, kAXTitleAttribute) ?? "",
      getAttributeString(el, kAXValueAttribute) ?? "",
        // getAttributeString(el, kAXDescriptionAttribute) ?? "",
        // getAttributeString(el, kAXLabelValueAttribute) ?? "",
    ].filter { str in !str.isEmpty }
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
    if !AXValueGetValue(positionValue, .cgPoint, &point) {
      return nil
    }
    return point
  }

  static func getBoundingRect(_ el: AXUIElement) -> CGRect? {
    guard let origin = getPoint(el), let size = getSize(el) else {
      return nil
    }
    return CGRect(origin: origin, size: size)
  }

  static func getParent(_ element: AXUIElement) -> AXUIElement? {
    var parent: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(element, kAXParentAttribute as CFString, &parent)

    if result != .success {
      return nil
    }

    return (parent as! AXUIElement)
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

  static func isInViewport(_ el: AXUIElement) -> Bool? {
    guard let parent = getParent(el), let parentRect = getBoundingRect(parent),
      let elRect = getBoundingRect(el)
    else {
      return nil
    }

    // print(
    //   "Pos for \(self.toString(el) ?? "Unkown") | \(parentRect.maxX)  \(elRect.maxX), \(parentRect.maxY) \(elRect.maxY), \(parentRect.minX)  \(elRect.minX), \(parentRect.minY)  \(elRect.minY) "
    // )

    return parentRect.maxX != elRect.maxX || parentRect.maxY != elRect.maxY
      || parentRect.minX != elRect.minX || parentRect.minY != elRect.minY
  }
}
