import ApplicationServices
import Cocoa
import SwiftUI

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
      let search =
        self.state.fzfMode
        ? self.state.search.lowercased().replacingOccurrences(of: " ", with: "") : state.search

      ZStack {
        ForEach(points.indices, id: \.self) { i in
          let text = state.texts[i]
          let hintOptions = (
            hintSize: AppOptions.shared.hintFontSize, padding: 4.0, shadowRadius: 6.0
          )

          let searchTarget = self.state.fzfMode ? state.hints[i].getSearchTerm() : text
          let isMatch =
            self.state.fzfMode
            ? search.isEmpty || searchTarget.contains(search) : text.starts(with: search)
          let nonFzfMatch = 1.0
          let fzfMatch = state.fzfSelectedIdx == i ? 1.0 : 0.5
          let opacity = isMatch ? state.fzfMode ? fzfMatch : nonFzfMatch : 0.001
          let zIndex = state.zIndexInverted ? Double(points.count) - Double(i) : Double(i)
          Tooltip(
            height: hintOptions.hintSize, position: points[i],
            backgroundColor: AppOptions.shared.colors.bg
          ) {
            Text(text.uppercased())
              .font(.system(size: hintOptions.hintSize, weight: .bold))
              .foregroundColor(AppOptions.shared.colors.fg)
              .padding([.horizontal], hintOptions.padding)
          }
          .zIndex(zIndex)
          .shadow(radius: hintOptions.shadowRadius)
          .opacity(opacity)
        }
      }.frame(width: geo.size.width, height: geo.size.height)
    }
  }
}

private struct Tooltip<Content: View>: View {
  let height: CGFloat
  let content: Content
  let position: CGPoint
  let backgroundColor: Color

  init(
    height: CGFloat, position: CGPoint, backgroundColor: Color, @ViewBuilder content: () -> Content
  ) {
    self.height = height
    self.content = content()
    self.position = position
    self.backgroundColor = backgroundColor
  }

  var body: some View {
    GeometryReader { geo in
      let isTop = geo.frame(in: .global).maxY - height * 2 < position.y
      let y =
        isTop
        ? (position.y - geo.frame(in: .global).minY - height)
        : (position.y - geo.frame(in: .global).minY + height / 2)
      VStack(alignment: .center, spacing: 0) {
        if isTop {
          content
            .background(backgroundColor)
            .cornerRadius(4)
            .frame(width: nil, height: height)
            .zIndex(2)
        }
        Triangle()
          .fill(backgroundColor)
          .rotationEffect(isTop ? .degrees(180) : .zero)
          .frame(width: height, height: AppOptions.shared.hintTriangleHeight)
          .zIndex(1)
        if !isTop {
          content
            .background(backgroundColor)
            .cornerRadius(4)
            .frame(width: nil, height: height)
            .zIndex(2)
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
