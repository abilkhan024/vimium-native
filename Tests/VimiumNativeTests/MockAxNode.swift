import CoreGraphics

@testable import VimiumNative

final class MockAxNode: AxNode {
  var role: AxRole?
  var frame: CGRect?
  var children: [MockAxNode]
  var actions: [String]
  var attributes: [String: String]

  init(
    role: AxRole?,
    frame: CGRect? = CGRect(x: 0, y: 0, width: 10, height: 10),
    children: [MockAxNode] = [],
    actions: [String] = [],
    attributes: [String: String] = [:]
  ) {
    self.role = role
    self.frame = frame
    self.children = children
    self.actions = actions
    self.attributes = attributes
  }

  func axRole() -> String? { role?.rawValue }

  func axAttributeString(_ attribute: String) -> String? { attributes[attribute] }

  func axPosition() -> CGPoint? { frame?.origin }

  func axSize() -> CGSize? { frame?.size }

  func axChildren() -> [AxNode] { children.map { $0 as AxNode } }

  func axActionNames() -> [String] { actions }

  func axPerformAction(_ action: String) -> Bool { actions.contains(action) }
}
