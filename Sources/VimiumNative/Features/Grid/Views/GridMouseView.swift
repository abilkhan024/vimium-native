import ApplicationServices
import Cocoa
import SwiftUI

struct GridMouseView: View {
  @ObservedObject var state = GridMouseState.shared

  var body: some View {
    let length = AppOptions.shared.mouse.size
    let color =
      state.dragging ? AppOptions.shared.mouse.colorVisual : AppOptions.shared.mouse.colorNormal
    let outlineWidth = AppOptions.shared.mouse.outlineWidth
    let outlineColor = AppOptions.shared.mouse.outlineColor
    let overlay = RoundedRectangle(cornerRadius: 10)
      .stroke(outlineColor, lineWidth: outlineWidth)

    GeometryReader { geo in
      Ellipse()
        .fill(color)
        .frame(width: length, height: length)
        .position(self.state.position)

      if let rect = state.focusedRect {
        ZStack {}
          .frame(width: rect.width, height: rect.height)
          .overlay(overlay)
          .position(x: rect.midX, y: rect.midY)
      } else {
        ZStack {}
          .frame(width: geo.frame(in: .global).width, height: geo.frame(in: .global).height)
          .overlay(overlay)
      }
    }
  }
}
