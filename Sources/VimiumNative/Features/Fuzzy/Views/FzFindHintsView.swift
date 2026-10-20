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
      let container = geo.frame(in: .global)
      let hintOptions = (
        hintSize: AppOptions.shared.hintFontSize, padding: 4.0, shadowRadius: 6.0
      )
      let font = AppOptions.shared.getPreferredFont(size: hintOptions.hintSize)
      let colors = AppOptions.shared.colors
      let border = AppOptions.shared.hintBorder
      let letterSpacing = AppOptions.shared.letterSpacing
      let triangleHeight = AppOptions.shared.hintTriangleHeight

      ZStack {
        ForEach(points.indices, id: \.self) { i in
          let text = state.texts[i]

          let searchTarget = self.state.fzfMode ? state.hints[i].getSearchTerm() : text
          let isMatch =
            self.state.fzfMode
            ? search.isEmpty || searchTarget.contains(search) : text.starts(with: search)
          let nonFzfMatch = 1.0
          let fzfMatch = state.fzfSelectedIdx == i ? 1.0 : 0.5
          let opacity = isMatch ? state.fzfMode ? fzfMatch : nonFzfMatch : 0.001
          let zIndex = state.zIndexInverted ? Double(points.count) - Double(i) : Double(i)

          if let bound = state.hints[i].bound {
            RoundedRectangle(cornerRadius: 10)
              .stroke(border, lineWidth: 1)
              .frame(width: bound.width, height: bound.height)
              .position(x: bound.midX - container.minX, y: bound.midY - container.minY)
              .zIndex(zIndex - 0.5)
              .opacity(opacity)
          }

          Tooltip(
            height: hintOptions.hintSize, triangleHeight: triangleHeight, position: points[i],
            container: container, backgroundColor: colors.bg
          ) {
            Text(text.uppercased())
              .font(font)
              .kerning(letterSpacing)
              .foregroundColor(colors.fg)
              .padding([.horizontal], hintOptions.padding)
          }
          .zIndex(zIndex)
          .shadow(radius: hintOptions.shadowRadius)
          .opacity(opacity)
        }
      }
      .frame(width: geo.size.width, height: geo.size.height)
      // Rasterize all hints (and their shadows) into a single Metal backed
      // layer instead of a CA layer + offscreen shadow pass per hint
      .drawingGroup()
    }
  }
}

// Positioned relative to `container` (global frame of the hints layer), so
// no GeometryReader is needed per hint
private struct Tooltip<Content: View>: View {
  let height: CGFloat
  let triangleHeight: CGFloat
  let content: Content
  let position: CGPoint
  let container: CGRect
  let backgroundColor: Color

  init(
    height: CGFloat, triangleHeight: CGFloat, position: CGPoint, container: CGRect,
    backgroundColor: Color, @ViewBuilder content: () -> Content
  ) {
    self.height = height
    self.triangleHeight = triangleHeight
    self.content = content()
    self.position = position
    self.container = container
    self.backgroundColor = backgroundColor
  }

  var body: some View {
    let isTop = container.maxY - height * 2 < position.y
    let y =
      isTop
      ? (position.y - container.minY - height)
      : (position.y - container.minY + height / 2)
    let x = position.x - container.minX
    VStack(alignment: .center, spacing: 0) {
      if isTop {
        label(anchorX: x)
      }
      Triangle()
        .fill(backgroundColor)
        .rotationEffect(isTop ? .degrees(180) : .zero)
        .frame(width: height, height: triangleHeight)
        .zIndex(1)
      if !isTop {
        label(anchorX: x)
      }
    }
    .position(x: x, y: y)
  }

  // Centered over the triangle, but shifted horizontally so it stays inside
  // the container near the left and right edges. The frame keeps the stack as
  // wide as the triangle, so the stack's center stays at the anchor
  private func label(anchorX: CGFloat) -> some View {
    let containerWidth = container.width
    return
      content
      .background(backgroundColor)
      .cornerRadius(4)
      .fixedSize()
      .frame(height: height)
      .alignmentGuide(HorizontalAlignment.center) { d in
        let shifted = min(max(d.width / 2, d.width - (containerWidth - anchorX)), anchorX)
        return min(max(shifted, 0), d.width)
      }
      .frame(width: height, alignment: .center)
      .zIndex(2)
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
