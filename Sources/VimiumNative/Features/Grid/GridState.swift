import SwiftUI

@MainActor
final class GridHintsState: ObservableObject {
  @Published var sequence: [String] = []
  @Published var search = ""
  @Published var matchingCount = 0
  @Published var rows = 0
  @Published var cols = 0
  @Published var hintWidth: CGFloat = 0
  @Published var hintHeight: CGFloat = 0

  static let shared = GridHintsState()

  private init() {}
}

@MainActor
class GridMouseState: ObservableObject {
  @Published var position = CGPointMake(0, 0)
  @Published var dragging = false
  @Published var focusedRect: CGRect?

  static let shared = GridMouseState()

  private init() {}
}
