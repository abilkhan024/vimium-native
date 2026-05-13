@preconcurrency import ApplicationServices
import Cocoa

enum AxRole: String {
  // MARK: - User's Input Roles
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
  case RadioButton = "AXRadioButton"

  // MARK: - Root & Layout Roles
  case Application = "AXApplication"
  case SystemWide = "AXSystemWide"
  case Desktop = "AXDesktop"
  case Pane = "AXPane"
  case LayoutArea = "AXLayoutArea"
  case LayoutItem = "AXLayoutItem"
  case SplitGroup = "AXSplitGroup"
  case Splitter = "AXSplitter"

  // MARK: - Interactive Controls
  case Button = "AXButton"
  case CheckBox = "AXCheckBox"
  case PopUpButton = "AXPopUpButton"
  case MenuButton = "AXMenuButton"
  case ColorWell = "AXColorWell"
  case Slider = "AXSlider"
  case Incrementor = "AXIncrementor"
  case ComboBox = "AXComboBox"

  // MARK: - Text & Fields
  case TextField = "AXTextField"
  case TextArea = "AXTextArea"
  case Heading = "AXHeading"

  // MARK: - Data Views & Containers
  case List = "AXList"
  case Grid = "AXGrid"
  case Table = "AXTable"
  case Column = "AXColumn"
  case Cell = "AXCell"
  case Browser = "AXBrowser"

  // MARK: - Menus & Overlays
  case MenuBar = "AXMenuBar"
  case MenuBarItem = "AXMenuBarItem"
  case Menu = "AXMenu"
  case MenuItem = "AXMenuItem"
  case Drawer = "AXDrawer"
  case Sheet = "AXSheet"
  case Popover = "AXPopover"

  // MARK: - Indicators & Status
  case ValueIndicator = "AXValueIndicator"
  case BusyIndicator = "AXBusyIndicator"
  case ProgressIndicator = "AXProgressIndicator"
  case RelevanceIndicator = "AXRelevanceIndicator"
  case LevelIndicator = "AXLevelIndicator"

  // MARK: - Date & Time
  case DateField = "AXDateField"
  case TimeField = "AXTimeField"
  case DateTimeArea = "AXDateTimeArea"

  // MARK: - System Components
  case ScrollBar = "AXScrollBar"
  case DisclosureTriangle = "AXDisclosureTriangle"
  case HelpTag = "AXHelpTag"
  case Matte = "AXMatte"
  case GrowArea = "AXGrowArea"
  case Handle = "AXHandle"
  case Image = "AXImage"
  case SheetPage = "AXPage"
  case Ruler = "AXRuler"
  case RulerMarker = "AXRulerMarker"
  case DockItem = "AXDockItem"
  case Unknown = "AXUnknown"
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
  var parents: [AxElement] = []
  private var searchTerm: String?

  private static let UNHINTABLE_ROLES: [AxRole] = [
    // MARK: - Structural & Containers
    .Group,
    .Window,
    .WebArea,
    .Outline,
    .Toolbar,
    .TabGroup,
    .Row,
    .ScrollArea,
    .RadioGroup,
    // .StaticText,

    // MARK: - Root & Layout Roles
    .Application,
    .SystemWide,
    .Desktop,
    .Pane,
    .LayoutArea,
    .LayoutItem,
    .SplitGroup,

    // MARK: - Text & Typography
    .Heading,

    // MARK: - Data Views & Containers
    .List,
    .Grid,
    .Table,
    .Column,
    .Browser,

    // MARK: - Menus & Overlays
    .MenuBar,
    .Menu,
    .Drawer,
    .Sheet,
    .Popover,

    // MARK: - Indicators & Status
    .ValueIndicator,
    .BusyIndicator,
    .ProgressIndicator,
    .RelevanceIndicator,
    .LevelIndicator,

    // MARK: - System Components
    .ScrollBar,
    .HelpTag,
    .Matte,
    .GrowArea,
    .Image,
    .SheetPage,
    .Ruler,
    .Unknown,

    // MARK: - Interactive Controls
    .Slider,
  ]

  private static let SMALL_NODE_THRESHOLD = 1000

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
    self.point = CGPointMake(
      point.x + size.width / 2,
      horizontalPoint
    )
    self.bound = CGRect(origin: point, size: size)
  }

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

  func getValidButton() -> Bool {
    let attributes = [
      getAttributeString(kAXTitleAttribute),
      getAttributeString(kAXValueAttribute),
      getAttributeString(kAXDescriptionAttribute),
      getAttributeString(kAXLabelValueAttribute),
    ]
    let idx = attributes.firstIndex(where: { val in val != nil })
    return idx != nil
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
    return "\(attribute): \(stringValue)"
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

  func getIsVisible() -> Bool {
    // make it fast for activity monitor
    guard let bound = self.bound else { return false }
    let visible = getRectVisible(bound)
    if !visible {
      return false
    }

    guard let parent = parents.last else { return true }
    let children = parent.getChildren()
    if children.count <= AxElement.SMALL_NODE_THRESHOLD {
      return true
    }
    var current = bound
    for parent in parents {
      guard let parentBound = parent.bound else { return false }
      current = current.intersection(parentBound)
    }
    return getRectVisible(current)
  }

  func printActions() {
    var names: CFArray?
    let error = AXUIElementCopyActionNames(self.raw, &names)

    if error != .success {
      return
    }

    let actions = Set(names! as [AnyObject] as! [String])
    print(actions)
  }

  // faster-more-precise-dfs if element at the position AXUIElementCopyElementAtPosition is not the same element then mark as false
  func getIsHintable(el: AxElement) -> Bool {
    guard let bound = el.bound, let role = el.role else {
      return false
    }

    // if role == .Button && !getValidButton() {
    //   return false
    // }

    if AxElement.UNHINTABLE_ROLES.contains(role) {
      return false
    }
    let isRectValid = !getRectHidden(bound)
    if !isRectValid {
      return false
    }

    if let directParent = parents.last,
      role == .StaticText && directParent.getIsHintable(el: directParent)
    {
      return false
    }

    return true
  }

  func findVisible() -> [AxElement] {
    if self.parents.contains(where: { parent in parent.raw == self.raw }) {
      return []
    }
    if getIsVisible() {
      let childList = getChildren().flatMap({ child in
        AxElement(child, parents: parents + [self]).findVisible()
      })

      let result = childList + [self]
      return result.filter({ el in getIsHintable(el: el) })
    }
    return []
  }
}
