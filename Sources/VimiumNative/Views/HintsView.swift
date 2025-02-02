import ApplicationServices
import Cocoa
import SwiftUI

struct HintsView: View {
  let els: [AXUIElement]
  let getPoint: (_: AXUIElement) -> CGPoint?
  let toString: (_: AXUIElement) -> String?

  init(
    els: [AXUIElement],
    getPoint: @escaping (_: AXUIElement) -> CGPoint?,
    toString: @escaping (_: AXUIElement) -> String?
  ) {
    self.els = els
    self.getPoint = getPoint
    self.toString = toString
  }

  var body: some View {
    ZStack {
      ForEach(els, id: \.self) { el in
        if let point = self.getPoint(el), let content = self.toString(el) {
          Text(content)
            .position(x: point.x, y: point.y)
            .foregroundColor(.red)
        } else {
          EmptyView()
        }
      }
    }
  }
}
