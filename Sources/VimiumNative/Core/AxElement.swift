@preconcurrency import ApplicationServices
import Cocoa

enum AxRole: String {
  case Link = "AXLink"
  case Group = "AXGroup"
  case Window = "AXWindow"
  case WebArea = "AXWebArea"
  case Outline = "AXOutline"
  case Toolbar = "AXToolbar"
  case TabGroup = "AXTabGroup"
  case Row = "AXRow"
  case ScrollArea = "AXScrollArea"
  case RadioGroup = "AXRadioGroup"
  case StaticText = "AXStaticText"
}

// NOTE: IDK if it's safe but it looks safe where it's being used
final class AxElement {
  let raw: AXUIElement

  var role: AxRole?
  var size: CGSize?
  var bound: CGRect?
  var rawPoint: CGPoint?
  // Point of the hint as opposed to element itself
  var point: CGPoint?
  private var parents: [AxElement] = []
  private var searchTerm: String?

  private let SMALL_NODE_THRESHOLD = 1000

  struct Flags {
    let traverseHidden: Bool
    let hintText: Bool
    let roleBased: Bool
  }

  init(_ raw: AXUIElement, parents: [AxElement] = []) {
    self.raw = raw
    self.parents = parents
    self.setup()
  }

  private func setup() {
    self.setRole()
    self.setDimensions()
  }

  private func setRole() {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(self.raw, kAXRoleAttribute as CFString, &value)
    guard result == .success, let role = value as? String else {
      return
    }
    self.role = AxRole.init(rawValue: role)
  }

  private func setDimensions() {
    var position: CFTypeRef?

    var result = AXUIElementCopyAttributeValue(self.raw, "AXPosition" as CFString, &position)
    guard result == .success else {
      return
    }
    let positionValue = (position as! AXValue)

    var point = CGPoint.zero
    if !AXValueGetValue(positionValue, .cgPoint, &point) {
      return
    }

    var value: AnyObject?
    result = AXUIElementCopyAttributeValue(self.raw, "AXSize" as CFString, &value)

    guard result == .success, let sizeValue = value as! AXValue? else { return }
    var size: CGSize = .zero
    if AXValueGetType(sizeValue) != .cgSize {
      return
    }
    AXValueGetValue(sizeValue, .cgSize, &size)

    self.size = size
    self.rawPoint = point
    let horizontalPoint = point.y + size.height / 2
    // if let rect = getFirstLineRect(for: self.raw), self.role == "AXText" || self.role == "AXLink" {
    //   print(debug(), rect)
    //   horizontalPoint = point.y + rect.height / 2
    // }
    self.point = CGPointMake(
      point.x + size.width / 2,
      horizontalPoint
    )
    self.bound = CGRect(origin: point, size: size)
  }

  // private func getFirstLineRect(for element: AXUIElement) -> CGRect? {
  //   var lineRangeValue: CFTypeRef?
  //
  //   // 1. Get the range for line index 0
  //   let rangeResult = AXUIElementCopyParameterizedAttributeValue(
  //     element,
  //     kAXRangeForLineParameterizedAttribute as CFString,
  //     0 as CFNumber,
  //     &lineRangeValue
  //   )
  //
  //   // Check success and that the pointer isn't nil
  //   guard rangeResult == .success, let axRange = lineRangeValue else {
  //     return nil
  //   }
  //
  //   // 2. Use the range to get bounds
  //   var boundsValue: CFTypeRef?
  //   let boundsResult = AXUIElementCopyParameterizedAttributeValue(
  //     element,
  //     kAXBoundsForRangeParameterizedAttribute as CFString,
  //     axRange,  // Pass the CFTypeRef directly
  //     &boundsValue
  //   )
  //
  //   // Use 'as' because the optionality is handled by the 'let'
  //   if boundsResult == .success, let axBounds = boundsValue {
  //     var rect = CGRect.zero
  //     // Extract the rect using the AXValue helper
  //     if AXValueGetValue(axBounds as! AXValue, .cgRect, &rect) {
  //       return rect
  //     }
  //   }
  //
  //   return nil
  // }

  private func getRectHidden(_ rect: CGRect) -> Bool {
    return rect.height <= 1 || rect.width <= 1
  }

  private func getRectVisible(_ rect: CGRect) -> Bool {
    return rect.width > 0 && rect.height > 0
  }

  func click() {
    let result = AXUIElementPerformAction(self.raw, kAXPressAction as CFString)
    if result == .success {
      print("Successfully triggered click")
    } else {
      print("Failed to trigger click: \(result)")
    }
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

  var children: [AXUIElement]? = nil

  private func getChildren() -> [AXUIElement] {
    var childrenRef: CFTypeRef?
    if let children = self.children {
      return children
    }

    let childResult = AXUIElementCopyAttributeValue(
      raw, kAXChildrenAttribute as CFString, &childrenRef)
    if childResult == .success, let children = childrenRef as? [AXUIElement] {
      self.children = children
    } else {
      self.children = []
    }
    return self.children!
  }

  func _getIsVisible() -> Bool {
    // make it fast for activity monitor
    guard let bound = self.bound else { return false }
    let visible = getRectVisible(bound)
    if !visible {
      return false
    }

    guard let parent = parents.last else { return true }
    let children = parent.getChildren()
    if children.count <= SMALL_NODE_THRESHOLD {
      return true
    }
    var current = bound
    for parent in parents {
      guard let parentBound = parent.bound else { return false }
      current = current.intersection(parentBound)
    }
    return getRectVisible(current)
  }

  func _getIsHintable(el: AxElement) -> Bool {
    guard let bound = el.bound, let role = el.role else {
      return false
    }

    if role == .Group || role == .Window || role == .WebArea || role == .Outline
      || role == .Toolbar || role == .TabGroup || role == .Row
      || role == .ScrollArea || role == .RadioGroup
    {
      return false
    }

    // if let value = el.getAttributeString(kAXValueAttribute),
    //   value.trimmingCharacters(in: .whitespaces).isEmpty && role == .StaticText
    // {
    //   return false
    // }

    let isRectValid = !getRectHidden(bound)
    // if let window = parents.first, let windowBound = window.bound {
    //   return !getRectHidden(windowBound.intersection(bound))
    //     /* && !getRectHidden(parentBound.intersection(bound)) */ && isRectValid
    // }

    return isRectValid

    // if role == "AXImage" || role == "AXCell" {
    //   return true
    // }
    //
    // if role == "AXWindow" || role == "AXScrollArea" {
    //   return false
    // }
    //
    // var names: CFArray?
    // let error = AXUIElementCopyActionNames(self.raw, &names)
    //
    // if error != .success {
    //   return false
    // }
    //
    // let actions = Set(names! as [AnyObject] as! [String])
    // let validActions = actions.subtracting(ignoredActions)
    // return !validActions.isEmpty
  }

  func findVisible() -> [AxElement] {
    if self.parents.contains(where: { parent in parent.raw == self.raw }) {
      return []
    }
    if _getIsVisible() {
      let childList = getChildren().flatMap({ child in
        AxElement(child, parents: parents + [self]).findVisible()
      })

      let result = childList + [self]
      return result.filter({ el in _getIsHintable(el: el) })
    }
    return []
  }
}
