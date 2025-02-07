import ApplicationServices
import Cocoa
import SwiftUI

struct HintsView: View {
  let els: [HintElement]

  init(els: [HintElement]) { self.els = els }

  var body: some View {
    ZStack {
      ForEach(els.indices, id: \.self) { i in
        let e = els[i]
        let el = e.axui
        if let point = AXUIElementUtils.getPoint(el),
          let size = AXUIElementUtils.getSize(el)
        {
          ZStack {
            Text(e.id)
              .font(.system(size: i == 0 ? 18 : 14))
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
