import ApplicationServices
import Cocoa
import SwiftUI

struct FzFindFastHintsView: View {
  @ObservedObject var state = FzFindFastState.shared
  @State private var progress: CGFloat = 0

  var body: some View {
    let opacity = 1.0
    // let opacity = state.visible ? 1 : 0.001
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

      let hints = state.hints.map { e in e.raw }
      ZStack {
        ForEach(hints.indices, id: \.self) { idx in
          if let position = state.hints[idx].point {
            //   let selected = state.hints.count == 1
            //   let scale = selected ? 1.2 : 1
            ZStack {
              Text(state.texts[idx])
                .font(.system(size: 14))
                .foregroundColor(.red)
            }
            // .frame(width: 36 * scale, height: 24 * scale)
            .background(.black)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(.red, lineWidth: 3))
            .cornerRadius(4)
            // .opacity(selected ? 1 : 0.75)
            .position(position)
          } else {
            Text("\(idx)")
          }
        }
      }.frame(width: geo.size.width, height: geo.size.height).opacity(opacity)
    }
  }
}
