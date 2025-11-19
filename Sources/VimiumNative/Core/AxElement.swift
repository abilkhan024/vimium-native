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
  private var parents: [AxElement] = []
  private var searchTerm: String?

  struct Flags {
    let traverseHidden: Bool
    let hintText: Bool
    let roleBased: Bool
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
    "AXOutline",
    "AXToolbar",
    // "AXGroup",
  ]

  private let ignoredActions: Set<String> = [
    "AXShowMenu",
    "AXScrollToVisible",
    "AXShowDefaultUI",
    "AXShowAlternateUI",
  ]

  init(_ raw: AXUIElement, parents: [AxElement] = []) {
    self.raw = raw
    self.parents = parents
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
    self.point = CGPointMake(
      point.x + size.width / 2,
      point.y + size.height / 2
    )
    self.bound = CGRect(origin: point, size: size)
  }

  private func getRectHidden(_ rect: CGRect) -> Bool {
    return rect.height <= 1 || rect.width <= 1
  }

  private func getRectVisible(_ rect: CGRect) -> Bool {
    return rect.width > 0 && rect.height > 0
  }

  func getIsHintable(_ flags: Flags) -> Bool {
    guard let role = self.role, let bound = self.bound else {
      return false
    }

    if getRectHidden(bound) {
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

    let actions = Set(names! as [AnyObject] as! [String])
    let validActions = actions.subtracting(ignoredActions)
    return !validActions.isEmpty
  }

  func getIsVisible(_ flags: AxElement.Flags) -> Bool? {
    guard let bound = bound else { return nil }
    let isVisible = getRectVisible(bound)
    if !isVisible {
      return false
    }
    self.setup()
    var currentBound = bound
    for parent in parents {
      guard let parentBound = parent.bound else { return nil }
      currentBound = currentBound.intersection(parentBound)
    }

    let visible = getRectVisible(currentBound)
    if !visible {
      self.setup()
      let parentsRo = parents
      DispatchQueue.main.async {
        var currentBound = bound
        for parent in parentsRo {
          guard let parentBound = parent.bound else { return }
          currentBound = currentBound.intersection(parentBound)
          print("parent", parentBound, "current", currentBound)
        }
      }
    }
    return visible

    // var currentBound = bound
    // var skippedUntilEnd = false
    // for parent in parents {
    //   guard let parentBound = parent.bound else { return nil }
    //   let nextBound = currentBound.intersection(parentBound)
    //   if !getRectVisible(nextBound) {
    //     skippedUntilEnd = true
    //   } else {
    //     currentBound = nextBound
    //     skippedUntilEnd = false
    //   }
    // }
    //
    // return !skippedUntilEnd
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

    let mxEle = 1000
    guard let parent = parents.last else { return true }
    let children = parent.getChildren()
    if children.count < mxEle {
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

    if role == "AXGroup" || role == "AXWindow" || role == "AXWebArea" {
      return false
    }

    let isRectValid = !getRectHidden(bound)
    if let window = parents.first, let parent = parents.last, let parentBound = parent.bound,
      let windowBound = window.bound
    {
      return !getRectHidden(windowBound.intersection(bound))
        /* && !getRectHidden(parentBound.intersection(bound)) */ && isRectValid
    }

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
