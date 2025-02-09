import ApplicationServices
import Cocoa
import SwiftUI

struct MouseView: View {
  let position: CGPoint
  let length: CGFloat

  init(position: CGPoint, length: CGFloat) {
    self.position = position
    self.length = length
  }

  var body: some View {
    Ellipse()
      .fill(Color.red)
      .frame(width: self.length, height: self.length)
      .position(self.position)
  }
}
