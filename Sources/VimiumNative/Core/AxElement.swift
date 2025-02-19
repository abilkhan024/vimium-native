import ApplicationServices
import Cocoa

// NOTE: IDK if it's safe but it looks safe where it's being used
final class AxElement: @unchecked Sendable {
  let raw: AXUIElement

  var role: String?
  var size: CGSize?
  var bound: CGRect?
  var rawPoint: CGPoint?
  // Point of the hint as opposed to element itself
  var point: CGPoint?

  struct Flags {
    let hintText: Bool
    let roleBased: Bool
  }

  struct Frame {
    let height: CGFloat
    let width: CGFloat
  }

  private let hintableRoles: Set<String> = [
    "AXButton",
    "AXComboBox",
    "AXCheckBox",
    "AXRadioButton",
    "AXLink",
    "AXImage",
    "AXCell",
    "AXMenuBarItem",
    "AXMenuItem",
    "AXMenuBar",
    "AXPopUpButton",
    "AXTextField",
    "AXSlider",
    "AXTabGroup",
    "AXTabButton",
    "AXTable",
    "AXOutline",
    "AXRow",
    "AXColumn",
    "AXScrollBar",
    "AXSwitch",
    "AXToolbar",
    "AXDisclosureTriangle",
  ]
  private let ignoredActions = [
    "AXShowMenu",
    "AXScrollToVisible",
    "AXShowDefaultUI",
    "AXShowAlternateUI",
  ]

  init(_ raw: AXUIElement) {
    self.raw = raw
    self.setup()
  }

  private func setup() {
    self.setDimensions()
    self.setRole()
  }

  private func setRole() {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(self.raw, kAXRoleAttribute as CFString, &value)
    guard result == .success, let role = value as? String else {
      return
    }
    self.role = role
  }

  private func setDimensions() {
    var position: CFTypeRef?

    var result = AXUIElementCopyAttributeValue(
      self.raw, kAXPositionAttribute as CFString, &position)
    guard result == .success else {
      return
    }
    let positionValue = (position as! AXValue)

    var point = CGPoint.zero
    if !AXValueGetValue(positionValue, .cgPoint, &point) {
      return
    }

    var value: AnyObject?
    result = AXUIElementCopyAttributeValue(self.raw, kAXSizeAttribute as CFString, &value)

    guard result == .success, let sizeValue = value as! AXValue? else { return }
    var size: CGSize = .zero
    if AXValueGetType(sizeValue) != .cgSize {
      return
    }
    AXValueGetValue(sizeValue, .cgSize, &size)

    self.size = size
    self.rawPoint = point
    self.point = CGPointMake(
      point.x + size.width / 2,
      point.y + size.height / 2
    )
    self.bound = CGRect(origin: point, size: size)
  }

  func getIsHintable(_ flags: Flags) -> Bool {
    guard let role = self.role else {
      return false
    }
    if flags.hintText && role == "AXStaticText" {
      return true
    }

    if flags.roleBased {
      return hintableRoles.contains(role)
    }

    if role == "AXImage" || role == "AXCell" {
      return true
    }

    if role == "AXWindow" || role == "AXScrollArea" {
      return false
    }

    var names: CFArray?
    let error = AXUIElementCopyActionNames(self.raw, &names)

    if error != .success {
      return false
    }

    let actions = names! as [AnyObject] as! [String]
    var count = 0
    for ignored in ignoredActions {
      for action in actions {
        if action == ignored {
          count += 1
        }
      }
    }

    let hasActions = actions.count > count

    return hasActions
  }

  func getIsVisible(_ frame: Frame, _ parents: [AxElement]) -> Bool? {
    guard let role = self.role, let elRect = self.bound else { return nil }

    if elRect.height == frame.height || elRect.width == frame.width {
      return true
    }

    let parentRects = parents.map { el in
      guard let rect = el.bound, el.role != "AXGroup" else {
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

// func toString(_ el: AXUIElement) -> String? {
//   let components = [
//     getAttributeString(el, kAXRoleAttribute) ?? "",
//     getAttributeString(el, kAXTitleAttribute) ?? "",
//     getAttributeString(el, kAXValueAttribute) ?? "",
//     getAttributeString(el, kAXDescriptionAttribute) ?? "",
//     getAttributeString(el, kAXLabelValueAttribute) ?? "",
//   ].filter { str in !str.isEmpty }
//   return components.isEmpty ? nil : components.joined(separator: ", ")
// }
//  func getAttributeString(_ el: AXUIElement, _ attribute: String) -> String? {
//   var value: CFTypeRef?
//   let result = AXUIElementCopyAttributeValue(el, attribute as CFString, &value)
//   guard result == .success, let stringValue = value as? String else {
//     return nil
//   }
//   return stringValue
// }
