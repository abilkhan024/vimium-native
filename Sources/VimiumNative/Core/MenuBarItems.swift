import ApplicationServices
import Cocoa

struct MenuBarItem: @unchecked Sendable {
  let raw: AxNode
  let attributes: AxTraversalAttributes
}

// Items are found by hit testing points along the menu bar, which gives the
// front app's menus and status items of every process, but not status items
// hidden behind the notch or the "Show Hidden Menu Bar Items" button
enum MenuBarItems {
  private static let step: CGFloat = 10
  // Hit tests of a chunk are sequential so that the points inside an item
  // already found are skipped, ~25ms in total vs ~330ms for every point in turn
  private static let chunks = 8
  // A hung app would otherwise stall the hints for AX's default ~6s
  private static let messagingTimeout: Float = 0.1
  private static let itemRoles = [AxRole.MenuBarItem.rawValue, AxRole.Button.rawValue]

  struct Unresponsive: Error {}

  static func fetch(menuBar: CGRect) -> [MenuBarItem] {
    return scan(menuBar) { point in
      // Timeout of the system-wide element would apply to every element of the
      // process, so it's left at the default
      let systemWide = AXUIElementCreateSystemWide()
      var element: AXUIElement?
      let result = AXUIElementCopyElementAtPosition(
        systemWide, Float(point.x), Float(point.y), &element)
      if result == .cannotComplete { throw Unresponsive() }
      guard result == .success, let element else { return nil }
      AXUIElementSetMessagingTimeout(element, messagingTimeout)
      return element
    }
  }

  // Elements at the points along the middle of `menuBar` (AX coordinates),
  // the same item may be found by neighbouring chunks
  static func scan(
    _ menuBar: CGRect, hitTest: @Sendable (CGPoint) throws -> AxNode?
  ) -> [MenuBarItem] {
    guard !menuBar.isEmpty else { return [] }
    let chunkWidth = menuBar.width / CGFloat(chunks)
    let lock = NSLock()
    nonisolated(unsafe) var result = [[MenuBarItem]](repeating: [], count: chunks)
    DispatchQueue.concurrentPerform(iterations: chunks) { i in
      var items: [MenuBarItem] = []
      var x = menuBar.minX + CGFloat(i) * chunkWidth
      let end = x + chunkWidth
      while x < end {
        let node: AxNode?
        do {
          node = try hitTest(CGPoint(x: x, y: menuBar.midY))
        } catch {
          break
        }
        let attributes = node?.axTraversalAttributes()
        // Gaps between the items hit the menu bar itself
        guard let node, let attributes, let role = attributes.role, itemRoles.contains(role)
        else {
          x += step
          continue
        }
        items.append(MenuBarItem(raw: node, attributes: attributes))
        let maxX = (attributes.position?.x ?? x) + (attributes.size?.width ?? 0)
        x = max(x + step, maxX + 1)
      }
      lock.withLock { result[i] = items }
    }
    return result.flatMap { items in items }
  }

  @MainActor
  static func hints(_ items: [MenuBarItem]) -> [AxElement] {
    return items.map { item in AxElement(item.raw, attributes: item.attributes) }
      .filter { el in el.isHintable }
  }

  // Menu bar of the hints window's screen, see AppWindowBuilder, flipped to AX
  // coordinates (origin at the top left of the primary screen)
  @MainActor
  static func menuBar() -> CGRect {
    guard let screen = NSScreen.main, let primary = NSScreen.screens.first?.frame
    else { return .null }
    // Visible frame includes the menu bar when it's hidden automatically
    let height = max(
      screen.frame.maxY - screen.visibleFrame.maxY, NSStatusBar.system.thickness)
    return CGRect(
      x: screen.frame.minX, y: primary.maxY - screen.frame.maxY,
      width: screen.frame.width, height: height)
  }
}
