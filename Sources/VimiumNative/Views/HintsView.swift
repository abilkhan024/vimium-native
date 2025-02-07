import ApplicationServices
import Cocoa
import SwiftUI

struct HintsView: View {
  let els: [AXUIElement]

  init(els: [AXUIElement]) { self.els = els }

  var body: some View {
    ZStack {
      ForEach(els.indices, id: \.self) { idx in
        let el = els[idx]
        if let point = AXUIElementUtils.getPoint(el),
          let size = AXUIElementUtils.getSize(el)
        {
          ZStack {
            Text(String(idx))
              .foregroundColor(.red)
          }
          // .frame(width: 28, height: 14)
          .background(.black)
          .clipShape(RoundedRectangle(cornerRadius: 4))
          .position(x: point.x + size.width / 2, y: point.y + size.height / 2)
        } else {
          EmptyView()
        }
      }
    }
  }
}
