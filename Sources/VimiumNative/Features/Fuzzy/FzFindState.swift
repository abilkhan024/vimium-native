import SwiftUI

@MainActor
final class FzFindState: ObservableObject {
  @Published var hints: [HintElement] = []

  static let shared = FzFindState()

  private init() {}
}
