import ApplicationServices
import Cocoa
import SwiftUI

struct HintsView: View {
  let els: [HintElement]

  init(els: [HintElement]) { self.els = els }

  var body: some View {
    ZStack {
      ForEach(els, id: \.self) { e in
        if let point = AXUIElementUtils.getPoint(e.axui),
          let size = AXUIElementUtils.getSize(e.axui)
        {
          let selected = els.count == 1
          let scale = selected ? 1.2 : 1
          ZStack {
            Text(e.id)
              .font(.system(size: 14 * scale))
              .foregroundColor(.red)
          }
          .frame(width: 36 * scale, height: 24 * scale)
          .background(.black)
          .clipShape(RoundedRectangle(cornerRadius: 4))
          .overlay(RoundedRectangle(cornerRadius: 4).stroke(.red, lineWidth: 3))
          .cornerRadius(4)
          .opacity(selected ? 1 : 0.75)
          .position(x: point.x + size.width / 2, y: point.y + size.height / 2)
        } else {
          EmptyView()
        }
      }
    }
  }
}
