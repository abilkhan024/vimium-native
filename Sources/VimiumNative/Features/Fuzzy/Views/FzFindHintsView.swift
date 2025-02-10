import ApplicationServices
import Cocoa
import SwiftUI

struct FzFindHintsView: View {
  @ObservedObject var state = FzFindState.shared

  var body: some View {
    GeometryReader { geo in
      ZStack {
        ForEach(state.hints, id: \.self) { e in
          if let position = AXUIElementUtils.getPosition(e.axui) {
            let selected = state.hints.count == 1
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
            .position(position)
          } else {
            EmptyView()
          }
        }
      }.frame(width: geo.size.width, height: geo.size.height)

    }
  }
}
