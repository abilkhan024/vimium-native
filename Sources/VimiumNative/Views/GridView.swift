import ApplicationServices
import Cocoa
import SwiftUI

// Following class is too verbose, because of the following error:
// ---
// The compiler is unable to type-check this expression in reasonable time; try
// breaking up the expression into distinct sub-expressions
// ---
struct GridView: View {
  @ObservedObject var state = AppState.get()

  var body: some View {
    let rows = state.rows
    let cols = state.cols
    let sequence = state.sequence
    let matchingCount = state.matchingCount
    let search = state.search
    let hintWidth = state.hintWidth
    let hintHeight = state.hintHeight

    Grid {
      ForEach(0..<rows, id: \.self) { i in
        GridRow {
          GridRowView(
            i: i,
            cols: cols,
            sequence: sequence,
            search: search,
            matchingCount: matchingCount,
            hintWidth: hintWidth,
            hintHeight: hintHeight
          )
        }
      }
    }
  }
}

struct GridRowView: View {
  private let i: Int
  private let cols: Int
  private let sequence: [String]
  private let search: String
  private let matchingCount: Int
  private let hintWidth: CGFloat
  private let hintHeight: CGFloat

  init(
    i: Int,
    cols: Int,
    sequence: [String],
    search: String,
    matchingCount: Int,
    hintWidth: CGFloat,
    hintHeight: CGFloat
  ) {
    self.i = i
    self.cols = cols
    self.sequence = sequence
    self.search = search
    self.matchingCount = matchingCount
    self.hintWidth = hintWidth
    self.hintHeight = hintHeight
  }

  var body: some View {
    ForEach(0..<self.cols, id: \.self) { j in
      let idx = self.i * cols + j

      GridItemView(
        text: self.sequence[idx],
        isMatching: self.sequence[idx].starts(with: self.search),
        isMatchingCount: self.matchingCount,
        hintWidth: self.hintWidth,
        hintHeight: self.hintHeight
      )
    }
  }

}

struct GridItemView: View {
  let text: String
  let isMatching: Bool
  let isMatchingCount: Int
  let hintWidth: CGFloat
  let hintHeight: CGFloat

  var body: some View {
    let opacity = isMatching && isMatchingCount == 1 ? 1 : !isMatching ? 0 : 0.4  // Moved opacity calculation here

    Text(text)
      .font(.system(size: 16))
      .foregroundColor(.red)
      .frame(width: hintWidth, height: hintHeight)
      .background(.black)
      .clipShape(RoundedRectangle(cornerRadius: 4))
      .overlay(RoundedRectangle(cornerRadius: 4).stroke(.red, lineWidth: 3))
      .cornerRadius(4)  // This is redundant after clipShape
      .opacity(opacity)
  }
}
