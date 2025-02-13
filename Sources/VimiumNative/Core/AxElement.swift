import ApplicationServices

@MainActor
class AxElement {
  let raw: AXUIElement
  var children: Set<AXUIElement> = []
  var point: CGPoint?
  private var revalidating = false

  init(_ raw: AXUIElement) {
    self.raw = raw

    self.point = self.getPoint()
  }

  func getPoint() -> CGPoint? {
    var position: CFTypeRef?

    let result = AXUIElementCopyAttributeValue(
      self.raw, kAXPositionAttribute as CFString, &position)
    guard result == .success else {
      return nil
    }
    let positionValue = (position as! AXValue)

    var point = CGPoint.zero
    if !AXValueGetValue(positionValue, .cgPoint, &point) {
      return nil
    }

    return point
  }

  func getChildren() {
    var children: CFTypeRef?
    let childResult = AxRequester.shared.copyAttribute(self.raw, kAXChildrenAttribute, &children)

    if childResult == .success, let childrenEls = children as? [AXUIElement] {
      for child in childrenEls {
        if AppState.shared.axMap[child] == nil {
          let el = AxElement(child)
          AppState.shared.axMap[child] = el
          self.children.insert(el.raw)
          el.getChildren()
        }
      }
    }
  }

  func revalidate() {
    if revalidating {
      return
    }
    revalidating = true
    getChildren()

    for child in self.children {
      guard let el = AppState.shared.axMap[child] else { continue }
      if el.isAlive() {
        el.revalidate()
      } else {
        children.remove(el.raw)
        AppState.shared.axMap[child] = nil
      }
    }
    revalidating = false
  }

  func getAliveNodes() -> [AxElement] {
    if !isAlive() {
      return []
    }
    var els: [AxElement] = [self]

    if children.count == 0 {
      getChildren()
    }

    for child in self.children {
      guard let el = AppState.shared.axMap[child] else { continue }
      if el.isAlive() {
        els.append(contentsOf: el.getAliveNodes())
      } else {
        children.remove(el.raw)
        AppState.shared.axMap[child] = nil
      }
    }

    return els
  }

  func isAlive() -> Bool {
    var value: CFTypeRef?
    let result = AxRequester.shared.copyAttribute(self.raw, kAXRoleAttribute, &value)
    if result == .success {
      return true
    }
    return false
  }
}
