import ApplicationServices
import Carbon.HIToolbox
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

// Seam over the raw Accessibility API so traversal/visibility logic can run
// against a mock tree in tests, without a real AXUIElement.
protocol AxNode: AnyObject {
  func axRole() -> String?
  func axAttributeString(_ attribute: String) -> String?
  func axPosition() -> CGPoint?
  func axSize() -> CGSize?
  func axChildren() -> [AxNode]
  func axActionNames() -> [String]
  func axPerformAction(_ action: String) -> Bool
}

extension AXUIElement: AxNode {
  func axRole() -> String? {
    return axAttributeString(kAXRoleAttribute)
  }

  func axAttributeString(_ attribute: String) -> String? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(self, attribute as CFString, &value)
    guard result == .success, let stringValue = value as? String else {
      return nil
    }
    return stringValue
  }

  func axPosition() -> CGPoint? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(self, "AXPosition" as CFString, &value)
    guard result == .success else { return nil }
    var point = CGPoint.zero
    guard AXValueGetValue((value as! AXValue), .cgPoint, &point) else { return nil }
    return point
  }

  func axSize() -> CGSize? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(self, "AXSize" as CFString, &value)
    guard result == .success, let sizeValue = value as! AXValue?,
      AXValueGetType(sizeValue) == .cgSize
    else { return nil }
    var size = CGSize.zero
    AXValueGetValue(sizeValue, .cgSize, &size)
    return size
  }

  func axChildren() -> [AxNode] {
    var childrenRef: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(self, kAXChildrenAttribute as CFString, &childrenRef)
    guard result == .success, let children = childrenRef as? [AXUIElement] else { return [] }
    return children
  }

  func axActionNames() -> [String] {
    var actionNames: CFArray?
    let result = AXUIElementCopyActionNames(self, &actionNames)
    guard result == .success, let actions = actionNames as? [String] else { return [] }
    return actions
  }

  func axPerformAction(_ action: String) -> Bool {
    return AXUIElementPerformAction(self, action as CFString) == .success
  }
}

@MainActor
final class AxElement {
  let raw: AxNode
  lazy var isVisible: Bool = { getIsVisible() }()
  lazy var isHintable: Bool = { getIsHintable() }()

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
    .Row,
    .ScrollArea,

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
    .SheetPage,
    .Ruler,
    .Unknown,

    // MARK: - Interactive Controls
    .Slider,
  ]

  init(_ raw: AxNode, parents: [AxElement] = []) {
    self.raw = raw
    self.parents = parents
    self.setup()
  }

  private func setup() {
    self.setRole()
    self.setDimensions()
  }

  private func setRole() {
    guard let role = raw.axRole() else { return }
    self.role = AxRole.init(rawValue: role)
  }

  private func setDimensions() {
    guard let point = raw.axPosition(), let size = raw.axSize() else { return }

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

  func canPress() -> Bool {
    return raw.axActionNames().contains(kAXPressAction)
  }

  // TODO: Suboptimal approach, because it doesn't account for event.flags
  // so no cmd+click, for now cmd behaviour is not
  func click() {
    if raw.axPerformAction(kAXPressAction) {
      print("Successfully triggered click")
    } else {
      print("Failed to trigger click")
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

  func getAttrs() -> [String?] {
    return [
      getAttributeString(kAXTitleAttribute),
      getAttributeString(kAXValueAttribute),
      getAttributeString(kAXDescriptionAttribute),
      getAttributeString(kAXLabelValueAttribute),
    ]
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
    return raw.axAttributeString(attribute)
  }

  var children: [AxNode]? = nil

  func getChildren() -> [AxNode] {
    if let children = self.children {
      return children
    }
    self.children = raw.axChildren()
    return self.children!
  }

  func getIsVisible() -> Bool {
    guard let bound = self.bound else { return false }
    let visible = getRectVisible(bound)
    if !visible {
      return false
    }

    guard let parent = parents.last else { return true }
    let children = parent.getChildren()
    if children.count <= AppOptions.shared.smallNodeThreshold {
      return true
    }

    // TODO: Sometimes too aggressive, find all places then debug
    // var current = bound
    // for parent in parents {
    //   guard let parentBound = parent.bound else { return false }
    //   current = current.intersection(parentBound)
    // }
    return getRectVisible(bound)
  }

  func normailzeWindowBound(bound: CGRect) -> CGRect {
    return CGRect(
      x: bound.minX, y: bound.minY, width: bound.width,
      height: bound.height - NSStatusBar.system.thickness)
  }

  func hasContent() -> Bool {
    let hasSomeContent = getAttrs().contains(where: { val in
      guard let str = val else { return false }
      let alphaNumeric = str.filter({ char in char.isLetter || char.isHexDigit })
      return !alphaNumeric.isEmpty
    })
    return hasSomeContent
  }

  // TODO: If element at the position AXUIElementCopyElementAtPosition is not the same element then mark as false
  // POTENTIAL: don't make hint labels sequential instead assign in random order to prevent focused overflow for leetcode (maybe via config flag)
  func getIsHintable() -> Bool {
    guard let bound = bound, let role = role else {
      return false
    }

    if getRectHidden(bound) {
      return false
    }

    if AxElement.UNHINTABLE_ROLES.contains(role) {
      return false
    }

    if role == .StaticText && parents.contains(where: { el in el.getIsHintable() }) {
      return false
    }

    if role == .StaticText && AppOptions.shared.hintText {
      return hasContent()
    }

    let bounds =
      parents.enumerated()
      .map({ (index, el) -> CGRect? in
        guard let bound = el.bound else { return nil }
        if index == 0 {
          return normailzeWindowBound(bound: bound)
        }
        return nil
      })
      .filter({ bound in bound != nil })

    var current = bound
    for parentBound in bounds {
      current = current.intersection(parentBound!)
    }

    return getRectVisible(current)
  }

  func findVisible() async -> [AxElement] {
    await Task.yield()
    if Task.isCancelled { return [] }
    guard !self.parents.contains(where: { parent in parent.raw === self.raw }) else { return [] }
    guard isVisible else { return [] }

    var childList: [AxElement] = []
    for child in getChildren() {
      childList.append(contentsOf: await AxElement(child, parents: parents + [self]).findVisible())
      if Task.isCancelled { return [] }
    }

    let result = childList + [self]
    return result.filter({ el in el.isHintable })
  }
}
