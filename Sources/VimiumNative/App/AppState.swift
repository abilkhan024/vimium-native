import SwiftUI

@MainActor
final class AppState {
  static let shared = AppState()
  private init() {}
}
