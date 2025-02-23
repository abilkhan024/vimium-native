import SwiftUI

@MainActor
final class FzFindState: ObservableObject {
  @Published var hints: [AxElement] = []
  @Published var texts: [String] = []
  @Published var loading = false
  @Published var search = ""
  @Published var zIndexInverted = false
  @Published var fzfSelectedIdx = -1
  @Published var fzfMode = false

  static let shared = FzFindState()

  private init() {}
}
