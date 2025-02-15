import ApplicationServices
import Cocoa
import SwiftUI

struct FzFindHintsView: View {
  @ObservedObject var state = FzFindState.shared
  @State private var progress: CGFloat = 0

  var body: some View {
    GeometryReader { geo in
      ZStack {
        if true {
          ProgressView(value: progress, total: 100)
            .progressViewStyle(LinearProgressViewStyle(tint: .blue))  // Customize the color
            .frame(width: geo.size.width, height: 4, alignment: .bottom)  // Adjust the width
            .scaleEffect(x: 1, y: 0.5, anchor: .center)  // Make it thinner
            .padding()
            .onAppear {
              withAnimation(.linear(duration: 2)) {  // 2-second animation
                self.progress = 100
              }
            }
            .onDisappear {
              progress = 0  // Reset for the next time it appears
            }
        }
      }.animation(.default, value: true)

      let points = state.hints.map { e in e.point! }
      ZStack {
        ForEach(points.indices, id: \.self) { i in

          let selected = state.hints.count == 1
          let scale = selected ? 1.2 : 1

          ZStack {
            Text(state.texts[i])
              .font(.system(size: 14 * scale))
              .foregroundColor(.red)
          }
          .frame(width: 36 * scale, height: 24 * scale)
          .background(.black)
          .clipShape(RoundedRectangle(cornerRadius: 4))
          .overlay(RoundedRectangle(cornerRadius: 4).stroke(.red, lineWidth: 3))
          .cornerRadius(4)
          .opacity(selected ? 1 : 0.75)
          .position(points[i])
        }
      }.frame(width: geo.size.width, height: geo.size.height)
    }
  }
}
