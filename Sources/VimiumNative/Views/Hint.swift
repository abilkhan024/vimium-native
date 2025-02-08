import ApplicationServices
import Cocoa
import SwiftUI

struct Hint: View {
  private var content: String
  private var position: CGPoint
  private var fontSize: CGFloat
  private var width: CGFloat
  private var height: CGFloat
  private var opacity: Double?

  init(
    content: String,
    position: CGPoint,
    fontSize: CGFloat,
    width: CGFloat,
    height: CGFloat,
    opacity: Double? = nil
  ) {
    self.content = content
    self.position = position
    self.fontSize = fontSize
    self.width = width
    self.height = height
    self.opacity = opacity
  }

  var body: some View {
    ZStack {
      ZStack {
        Text(self.content)
          .font(.system(size: self.fontSize))
          .foregroundColor(.red)
      }
      .frame(width: self.width, height: self.height)
      .background(.black)
      .clipShape(RoundedRectangle(cornerRadius: 4))
      .overlay(RoundedRectangle(cornerRadius: 4).stroke(.red, lineWidth: 3))
      .cornerRadius(4)
      .opacity(self.opacity ?? 1)
      .position(self.position)
    }
  }
}
