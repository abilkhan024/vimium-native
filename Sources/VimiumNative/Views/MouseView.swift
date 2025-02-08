import ApplicationServices
import Cocoa
import SwiftUI

struct MouseView: View {
  let position: CGPoint

  init(position: CGPoint) { self.position = position }

  var body: some View {
    ZStack {
      Text("Test").foregroundColor(.blue)
    }.position(self.position)
      .background(.red)
      .frame(width: 40, height: 40)
      .cornerRadius(999)
  }
}
