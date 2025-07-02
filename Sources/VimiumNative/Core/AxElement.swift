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
  private var searchTerm: String?

  struct Flags {
    let traverseHidden: Bool
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
    guard let role = self.role, let bound = self.bound else {
      return false
    }
    if bound.height <= 1 || bound.width <= 1 {
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

  // NOTE: Until next time can do dynamic refetch with new config params
  // private var childRequested = false
  // var children: [Child] = []
  // struct Child {
  //   let raw: AXUIElement
  //   var wrapped: AxElement?
  // }
  // func getChildren() -> [Child] {
  //   if childRequested {
  //     return self.children
  //   }
  //   var childrenRef: CFTypeRef?
  //   let childResult = AXUIElementCopyAttributeValue(
  //     self.raw, kAXChildrenAttribute as CFString, &childrenRef)
  //   self.childRequested = true
  //   if childResult == .success, let children = childrenRef as? [AXUIElement] {
  //     self.children = children.map { raw in Child(raw: raw, wrapped: nil) }
  //   }
  //   return self.children
  // }

  func getIsVisible(_ frame: Frame, _ parents: [AxElement], _ flags: AxElement.Flags) -> Bool? {
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

    if !flags.traverseHidden {
      return elRect.height > 1 && elRect.width > 1
    }
    return true
  }

  func getSortableKey() -> String {
    guard let bound = self.bound, let role = self.role else {
      print("Impossible case when visible doesn't have basic fields, but unsafe to throw")
      return ""
    }
    return "\(bound.minX)\(bound.maxX)\(bound.minY)\(bound.maxY)\(role)\(getSearchTerm())"
  }

  func getSearchTerm() -> String {
    if self.searchTerm != nil {
      return self.searchTerm!
    }
    if let val = getAttributeString(kAXValueAttribute), !val.isEmpty {
      self.searchTerm = val
    } else if let val = getAttributeString(kAXDescriptionAttribute), !val.isEmpty {
      self.searchTerm = val
    } else if let val = getAttributeString(kAXTitleAttribute), !val.isEmpty {
      self.searchTerm = val
    } else {
      self.searchTerm = ""
    }
    self.searchTerm = self.searchTerm!.lowercased().replacingOccurrences(of: " ", with: "")
    return self.searchTerm!
  }

  func debug() -> String {
    let components = [
      getAttributeString(kAXRoleAttribute) ?? "",
      getAttributeString(kAXTitleAttribute) ?? "",
      getAttributeString(kAXValueAttribute) ?? "",
      getAttributeString(kAXDescriptionAttribute) ?? "",
      getAttributeString(kAXLabelValueAttribute) ?? "",
    ].filter { str in !str.isEmpty }

    return components.isEmpty ? "NO_DEBUG_INFO" : components.joined(separator: ", ")
  }

  private func getAttributeString(_ attribute: String) -> String? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(self.raw, attribute as CFString, &value)
    guard result == .success, let stringValue = value as? String else {
      return nil
    }
    return stringValue
  }
}
