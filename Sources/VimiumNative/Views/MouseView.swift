import ApplicationServices
import Cocoa
import SwiftUI

struct MouseView: View {
  let position: CGPoint

  init(position: CGPoint) { self.position = position }

  var body: some View {
    Hint(content: "OD", position: CGPointMake(40, 40), fontSize: 16, width: 40, height: 20)
    Ellipse()
      .fill(Color.red)
      .frame(width: 10, height: 10)
      .position(self.position)
  }
}
