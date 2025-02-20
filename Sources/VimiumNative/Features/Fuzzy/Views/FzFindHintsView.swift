import ApplicationServices
import Cocoa
import SwiftUI

private struct Tooltip<Content: View>: View {
  let content: Content
  let position: CGPoint
  let backgroundColor: Color

  init(position: CGPoint, backgroundColor: Color, @ViewBuilder content: () -> Content) {
    self.content = content()
    self.position = position
    self.backgroundColor = backgroundColor
  }

  var body: some View {
    let triangle = (width: 8.0, height: 4.0)
    GeometryReader { geo in
      let height = 14.0
      let isTop = geo.frame(in: .global).maxY - height * 2 < position.y
      let y =
        isTop
        ? (position.y - geo.frame(in: .global).minY - height)
        : (position.y - geo.frame(in: .global).minY + height / 2)
      VStack {
        if isTop {
          content
            .background(backgroundColor)
            .cornerRadius(4)
            .offset(x: 0, y: height / 2)
            .frame(width: nil, height: height)
        }
        Triangle()
          .fill(backgroundColor)
          .rotationEffect(isTop ? .degrees(180) : .zero)
          .frame(width: triangle.width, height: triangle.height)
          .offset(x: 0, y: isTop ? 0 : height / 2)
        if !isTop {
          content
            .background(backgroundColor)
            .cornerRadius(4)
            .frame(width: nil, height: height)
        }
      }
      .position(
        x: position.x - geo.frame(in: .global).minX,
        y: y
      )
    }
  }
}

private struct Triangle: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.midX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    path.closeSubpath()
    return path
  }
}

struct FzFindHintsView: View {
  @ObservedObject var state = FzFindState.shared

  var body: some View {
    GeometryReader { geo in
      if state.loading {
        ZStack {
          ProgressView()
            .progressViewStyle(.circular)
            .frame(width: geo.size.width, height: geo.size.height)
        }
      }

      let points = state.hints.map { e in e.point! }
      ZStack {
        ForEach(points.indices, id: \.self) { i in
          let text = state.texts[i]
          let isMatch = text.starts(with: state.search)
          let zIndex = state.zIndexInverted ? Double(points.count) - Double(i) : Double(i)
          Tooltip(position: points[i], backgroundColor: AppOptions.shared.colors.bg) {
            Text(text.uppercased())
              .font(.system(size: 14, weight: .bold))
              .foregroundColor(AppOptions.shared.colors.fg)
              .padding([.horizontal], 4)
          }
          .zIndex(zIndex)
          .shadow(radius: 6.0)
          .opacity(isMatch ? 1 : 0.001)
        }
      }.frame(width: geo.size.width, height: geo.size.height)
    }
  }
}
