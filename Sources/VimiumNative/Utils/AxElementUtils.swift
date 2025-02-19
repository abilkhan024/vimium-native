import ApplicationServices
import Cocoa
import SwiftUI

class AxElementUtils {
  static func toString(_ el: AXUIElement) -> String? {
    let components = [
      getAttributeString(el, kAXRoleAttribute) ?? "",
      getAttributeString(el, kAXTitleAttribute) ?? "",
      getAttributeString(el, kAXValueAttribute) ?? "",
      getAttributeString(el, kAXDescriptionAttribute) ?? "",
      getAttributeString(el, kAXLabelValueAttribute) ?? "",
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

  static func getPosition(_ el: AXUIElement) -> CGPoint? {
    guard let point = getPoint(el), let size = getSize(el) else {
      return nil
    }

    return CGPoint(x: point.x + size.width / 2, y: point.y + size.height / 2)
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

  static func getIsVisible(_ el: AXUIElement, _ parents: [AXUIElement] = []) -> Bool? {
    guard let elRect = getBoundingRect(el), let screen = NSScreen.main,
      let role = getAttributeString(el, kAXRoleAttribute)
    else { return nil }

    if elRect.height == screen.frame.height || elRect.width == screen.frame.width {
      return true
    }

    let parentRects = parents.map { el in
      guard let rect = getBoundingRect(el) else {
        let max = CGFloat(Float.greatestFiniteMagnitude)
        let min = CGFloat(-Float.greatestFiniteMagnitude)
        return (maxX: max, maxY: max, minX: min, minY: min)
      }
      return (maxX: rect.maxX, maxY: rect.maxY, minX: rect.minX, minY: rect.minY)
    }

    if role != "AXGroup" && role != "AXMenu" {
      if let maxX = parentRects.map({ e in e.maxX }).min(), maxX - elRect.minX <= 1 {
        return false
      } else if let maxY = parentRects.map({ e in e.maxY }).min(), maxY - elRect.minY <= 1 {
        return false
      } else if let minX = parentRects.map({ e in e.minX }).max(), elRect.maxX - minX <= 1 {
        return false
      } else if let minY = parentRects.map({ e in e.minY }).max(), elRect.maxY - minY <= 1 {
        return false
      }
    }

    return elRect.height > 1 && elRect.width > 1
  }
}
