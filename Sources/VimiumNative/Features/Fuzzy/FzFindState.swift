import SwiftUI

@MainActor
final class FzFindState: ObservableObject {
  @Published var hints: [AxElement] = []
  @Published var texts: [String] = []
  @Published var loading = false
  @Published var search = ""
  @Published var zIndexInverted = false

  static let shared = FzFindState()

  private init() {}
}
