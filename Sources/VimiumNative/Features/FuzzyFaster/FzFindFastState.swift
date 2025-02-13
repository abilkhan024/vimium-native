import SwiftUI

@MainActor
final class FzFindFastState: ObservableObject {
  @Published var hints: [AxElement] = []
  @Published var texts: [String] = []
  @Published var loading = false
  @Published var visible = false

  static let shared = FzFindFastState()

  private init() {}
}
