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

    ZStack {
      Ellipse()
        .fill(color)
        .frame(width: length, height: length)
        .position(self.state.position)
    }.overlay(
      RoundedRectangle(cornerRadius: 10)
        .stroke(outlineColor, lineWidth: outlineWidth)
    )
  }
}
