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
  // Everything traversal needs per node, ideally in a single round trip
  func axTraversalAttributes() -> AxTraversalAttributes
  // DEVELOPMENT ONLY: Any attribute value formatted as text, see TraversalRecorder
  func axDebugAttributes(_ attributes: [String]) -> [String?]
}

struct AxTraversalAttributes {
  var role: String?
  var position: CGPoint?
  var size: CGSize?
  var children: [AxNode] = []
}

extension AxNode {
  func axTraversalAttributes() -> AxTraversalAttributes {
    return AxTraversalAttributes(
      role: axRole(), position: axPosition(), size: axSize(), children: axChildren())
  }

  func axDebugAttributes(_ attributes: [String]) -> [String?] {
    return attributes.map { attribute in axAttributeString(attribute) }
  }
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

  // Each AX call is an IPC round trip to the target app, so fetch all
  // traversal attributes at once. Missing attributes come back as AXValue
  // errors in their slot and end up nil
  func axTraversalAttributes() -> AxTraversalAttributes {
    let attributes =
      [
        kAXRoleAttribute, kAXPositionAttribute, kAXSizeAttribute, kAXChildrenAttribute,
      ] as CFArray
    var valuesRef: CFArray?
    let result = AXUIElementCopyMultipleAttributeValues(
      self, attributes, AXCopyMultipleAttributeOptions(rawValue: 0), &valuesRef)
    guard result == .success, let values = valuesRef as? [AnyObject], values.count == 4 else {
      return AxTraversalAttributes(
        role: axRole(), position: axPosition(), size: axSize(), children: axChildren())
    }

    var traversal = AxTraversalAttributes(
      role: values[0] as? String, children: values[3] as? [AXUIElement] ?? [])
    var position = CGPoint.zero
    if let value = AXUIElement.axValue(values[1], .cgPoint),
      AXValueGetValue(value, .cgPoint, &position)
    {
      traversal.position = position
    }
    var size = CGSize.zero
    if let value = AXUIElement.axValue(values[2], .cgSize), AXValueGetValue(value, .cgSize, &size) {
      traversal.size = size
    }
    return traversal
  }

  func axDebugAttributes(_ attributes: [String]) -> [String?] {
    var valuesRef: CFArray?
    let result = AXUIElementCopyMultipleAttributeValues(
      self, attributes as CFArray, AXCopyMultipleAttributeOptions(rawValue: 0), &valuesRef)
    guard result == .success, let values = valuesRef as? [AnyObject],
      values.count == attributes.count
    else { return attributes.map { _ in nil } }
    return values.map { value in AXUIElement.debugString(value) }
  }

  private static func debugString(_ value: AnyObject) -> String? {
    if CFGetTypeID(value) == AXValueGetTypeID() {
      // Missing attributes come back as AXValue errors
      let axValue = value as! AXValue
      return AXValueGetType(axValue) == .axError ? nil : "\(axValue)"
    }
    if CFGetTypeID(value) == CFBooleanGetTypeID() {
      return CFBooleanGetValue((value as! CFBoolean)) ? "true" : "false"
    }
    if CFGetTypeID(value) == AXUIElementGetTypeID() {
      return "<element>"
    }
    if let array = value as? [AnyObject] {
      return "[" + array.compactMap { debugString($0) }.joined(separator: ", ") + "]"
    }
    return "\(value)"
  }

  private static func axValue(_ value: AnyObject, _ type: AXValueType) -> AXValue? {
    guard CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
    let axValue = value as! AXValue
    return AXValueGetType(axValue) == type ? axValue : nil
  }
}

// Why AxElement.findVisible didn't turn a node into a hint, see TraversalRecorder
enum AxSkipReason: String {
  // MARK: - Subtree is skipped as well
  case cycle = "cycle"
  case noBound = "no-bound"
  case emptyBound = "empty-bound"
  case offscreen = "offscreen"

  // MARK: - Only the element itself is skipped
  case unknownRole = "unknown-role"
  case tooSmall = "too-small"
  case unhintableRole = "unhintable-role"
  case textInsideHintable = "text-inside-hintable"
  case textWithoutContent = "text-without-content"
  case outsideWindow = "outside-window"
  // Bound has no area, but children are traversed, see ignore_empty_depth
  case emptyTraversed = "empty-traversed"
  // Hinted, but dropped because another hint has the same point
  case duplicatePoint = "duplicate-point"
}

@MainActor
final class AxElement {
  let raw: AxNode
  lazy var isVisible: Bool = { getIsVisible() }()
  // Empty bound elements in a row ending with this one, see ignore_empty_depth
  lazy var emptyDepth: Int = {
    getInvisibleReason() == .emptyBound ? (parents.last?.emptyDepth ?? 0) + 1 : 0
  }()
  lazy var isHintable: Bool = { BenchUtils.measure("isHintable") { getIsHintable() } }()

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
    let attributes = BenchUtils.measure("ax: role+position+size+children (batched)") {
      raw.axTraversalAttributes()
    }
    if let role = attributes.role {
      self.role = AxRole.init(rawValue: role)
    }
    self.setDimensions(position: attributes.position, size: attributes.size)
    self.children = attributes.children
  }

  private func setDimensions(position: CGPoint?, size: CGSize?) {
    guard let point = position, let size = size else { return }

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
    let searchTermStart = BenchUtils.now()
    defer { BenchUtils.add("ax: searchTerm (uncached)", BenchUtils.now() - searchTermStart) }
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

  // Text shown to the user, falls back to the descendants' text since
  // controls like buttons and links usually render it via StaticText children
  func getCopyText() -> String? {
    if let text = AxElement.ownText(raw) {
      return text
    }
    let texts = AxElement.descendantTexts(getChildren(), depth: 8)
    return texts.isEmpty ? nil : texts.joined(separator: " ")
  }

  static func ownText(_ node: AxNode) -> String? {
    let attributes = [kAXValueAttribute, kAXTitleAttribute, kAXDescriptionAttribute]
    for attribute in attributes {
      if let text = node.axAttributeString(attribute)?.trimmingCharacters(
        in: .whitespacesAndNewlines), !text.isEmpty
      {
        return text
      }
    }
    return nil
  }

  private static func descendantTexts(_ nodes: [AxNode], depth: Int) -> [String] {
    guard depth > 0 else { return [] }
    var texts: [String] = []
    for node in nodes {
      if node.axRole() == AxRole.StaticText.rawValue, let text = ownText(node) {
        texts.append(text)
      } else {
        texts.append(contentsOf: descendantTexts(node.axChildren(), depth: depth - 1))
      }
    }
    return texts
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
    self.children = BenchUtils.measure("ax: children") { raw.axChildren() }
    return self.children!
  }

  func getIsVisible() -> Bool {
    return getInvisibleReason() == nil
  }

  // nil when visible, otherwise why the element and its subtree are skipped
  func getInvisibleReason() -> AxSkipReason? {
    guard let bound = self.bound else { return .noBound }
    let visible = getRectVisible(bound)
    if !visible {
      return .emptyBound
    }

    guard let parent = parents.last else { return nil }
    let children = parent.getChildren()
    if children.count <= AppOptions.shared.smallNodeThreshold {
      return nil
    }

    // TODO: Sometimes too aggressive, find all places then debug
    // var current = bound
    // for parent in parents {
    //   guard let parentBound = parent.bound else { return false }
    //   current = current.intersection(parentBound)
    // }
    return getRectVisible(bound) ? nil : .emptyBound
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
    return getUnhintableReason() == nil
  }

  // nil when hintable, otherwise why the element itself isn't hinted
  func getUnhintableReason() -> AxSkipReason? {
    guard let bound = bound else { return .noBound }
    guard let role = role else { return .unknownRole }

    if getRectHidden(bound) {
      return .tooSmall
    }

    if AxElement.UNHINTABLE_ROLES.contains(role) {
      return .unhintableRole
    }

    if role == .StaticText && parents.contains(where: { el in el.getIsHintable() }) {
      return .textInsideHintable
    }

    if role == .StaticText && AppOptions.shared.hintText {
      return hasContent() ? nil : .textWithoutContent
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

    return getRectVisible(current) ? nil : .outsideWindow
  }

  // nil when children should be traversed, otherwise why the element and its
  // whole subtree are skipped
  func getPruneReason() -> AxSkipReason? {
    if parents.contains(where: { parent in parent.raw === self.raw }) {
      return .cycle
    }
    if !isVisible {
      let reason = getInvisibleReason() ?? .emptyBound
      if reason == .emptyBound && emptyDepth <= AppOptions.shared.ignoreEmptyDepth {
        return nil
      }
      return reason
    }
    // Element itself can't be hinted outside the window (see getIsHintable),
    // and its subtree is assumed to stay within its bound, so skip it whole
    if let window = parents.first?.bound, let bound, !bound.intersects(window) {
      return .offscreen
    }
    return nil
  }

  // nil when hinted, otherwise why not, mirrors findVisible
  func getSkipReason() -> AxSkipReason? {
    if let reason = getPruneReason() { return reason }
    if isHintable { return nil }
    return isVisible ? getUnhintableReason() : .emptyTraversed
  }

  func findVisible() async -> [AxElement] {
    let yieldStart = BenchUtils.now()
    await Task.yield()
    BenchUtils.add("Task.yield (main busy elsewhere)", BenchUtils.now() - yieldStart)
    if Task.isCancelled { return [] }
    if let reason = getPruneReason() {
      if reason == .offscreen {
        BenchUtils.count("pruned offscreen subtrees")
        BenchUtils.count("pruned offscreen direct children", by: getChildren().count)
      }
      TraversalRecorder.record(self, reason)
      return []
    }
    // Recorded before the children so the log keeps the tree order
    TraversalRecorder.record(self, getSkipReason())

    var childList: [AxElement] = []
    for child in getChildren() {
      childList.append(contentsOf: await AxElement(child, parents: parents + [self]).findVisible())
      if Task.isCancelled { return [] }
    }

    let result = childList + [self]
    return result.filter({ el in el.isHintable })
  }
}
