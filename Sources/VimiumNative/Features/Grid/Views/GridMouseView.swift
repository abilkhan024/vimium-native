import ApplicationServices
import Cocoa
import SwiftUI

struct GridMouseView: View {
  @ObservedObject var state = GridMouseState.shared
  let length: CGFloat

  init(length: CGFloat) {
    self.length = length
  }

  var body: some View {
    Ellipse()
      .fill(state.dragging ? Color.blue : Color.red)
      .frame(width: self.length, height: self.length)
      .position(self.state.position)
  }
}
