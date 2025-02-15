import ApplicationServices

@MainActor
class AxElement {
  let raw: AXUIElement
  var point: CGPoint?

  init(_ raw: AXUIElement) {
    self.raw = raw
    self.setup()
  }

  private func setup() {
    self.setPoint()
  }

  private func setPoint() {
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

    self.point = CGPointMake(
      point.x + size.width / 2,
      point.y + size.height / 2
    )
  }
}
