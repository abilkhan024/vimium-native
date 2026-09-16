import CoreGraphics
import XCTest

@testable import VimiumNative

@MainActor
final class AxElementTests: XCTestCase {

  func testVisibleButtonIsReturned() async {
    let button = MockAxNode(role: .Button, frame: CGRect(x: 0, y: 0, width: 20, height: 20))
    let window = MockAxNode(
      role: .Window, frame: CGRect(x: 0, y: 0, width: 200, height: 200), children: [button])

    let result = await AxElement(window).findVisible()

    XCTAssertEqual(result.count, 1)
    XCTAssertEqual(result.first?.role, .Button)
  }

  func testZeroSizedElementIsExcluded() async {
    let hiddenButton = MockAxNode(role: .Button, frame: CGRect(x: 0, y: 0, width: 0, height: 20))
    let visibleButton = MockAxNode(role: .Button, frame: CGRect(x: 0, y: 0, width: 20, height: 20))
    let window = MockAxNode(
      role: .Window, frame: CGRect(x: 0, y: 0, width: 200, height: 200),
      children: [hiddenButton, visibleButton])

    let result = await AxElement(window).findVisible()

    XCTAssertEqual(result.count, 1)
    XCTAssertEqual(result.first?.bound?.width, 20)
  }

  func testUnhintableContainerRoleIsSkippedButChildrenAreKept() async {
    let button = MockAxNode(role: .Button, frame: CGRect(x: 0, y: 0, width: 20, height: 20))
    let group = MockAxNode(
      role: .Group, frame: CGRect(x: 0, y: 0, width: 100, height: 100), children: [button])
    let window = MockAxNode(
      role: .Window, frame: CGRect(x: 0, y: 0, width: 200, height: 200), children: [group])

    let result = await AxElement(window).findVisible()

    XCTAssertEqual(result.count, 1)
    XCTAssertEqual(result.first?.role, .Button)
  }

  func testStaticTextNestedInHintableParentIsExcluded() async {
    let label = MockAxNode(
      role: .StaticText, frame: CGRect(x: 0, y: 0, width: 10, height: 10),
      attributes: [kAXValueAttribute: "hello"])
    let button = MockAxNode(
      role: .Button, frame: CGRect(x: 0, y: 0, width: 20, height: 20), children: [label])
    let window = MockAxNode(
      role: .Window, frame: CGRect(x: 0, y: 0, width: 200, height: 200), children: [button])

    let result = await AxElement(window).findVisible()

    XCTAssertEqual(result.count, 1)
    XCTAssertEqual(result.first?.role, .Button)
  }

  func testStaticTextIsHintableWhenOptionEnabledAndNotNestedInHintableParent() async {
    AppOptions.shared.hintText = true
    defer { AppOptions.shared.hintText = false }

    let label = MockAxNode(
      role: .StaticText, frame: CGRect(x: 0, y: 0, width: 10, height: 10),
      attributes: [kAXValueAttribute: "hello"])
    let group = MockAxNode(
      role: .Group, frame: CGRect(x: 0, y: 0, width: 100, height: 100), children: [label])
    let window = MockAxNode(
      role: .Window, frame: CGRect(x: 0, y: 0, width: 200, height: 200), children: [group])

    let result = await AxElement(window).findVisible()

    XCTAssertEqual(result.count, 1)
    XCTAssertEqual(result.first?.role, .StaticText)
  }

  func testCyclicTreeDoesNotRecurseInfinitelyAndDropsRevisitedAncestor() async {
    // Frames are kept much taller than a status bar so intersection against
    // the normalized parent bound (window height - status bar thickness)
    // stays positive; this isn't about status bar behavior, just avoiding it.
    let nodeA = MockAxNode(role: .Button, frame: CGRect(x: 0, y: 0, width: 200, height: 800))
    let nodeB = MockAxNode(role: .Button, frame: CGRect(x: 0, y: 0, width: 200, height: 800))
    nodeA.children = [nodeB]
    nodeB.children = [nodeA]

    let result = await AxElement(nodeA).findVisible()

    XCTAssertEqual(result.count, 2)
  }

  func testCancelledTraversalReturnsEmpty() async {
    let button = MockAxNode(role: .Button, frame: CGRect(x: 0, y: 0, width: 20, height: 20))
    let window = MockAxNode(
      role: .Window, frame: CGRect(x: 0, y: 0, width: 200, height: 200), children: [button])

    let task = Task { await AxElement(window).findVisible() }
    task.cancel()
    let result = await task.value

    XCTAssertTrue(result.isEmpty)
  }
}
