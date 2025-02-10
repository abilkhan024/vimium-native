import SwiftUI

@MainActor
final class FzFindState: ObservableObject {
  @Published var hints: [HintElement] = []
  @Published var loading = false

  static let shared = FzFindState()

  private init() {}
}
