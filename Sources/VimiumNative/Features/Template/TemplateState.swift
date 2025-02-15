import SwiftUI

@MainActor
final class TemplateState: ObservableObject {
  @Published var flag = false

  static let shared = TemplateState()

  private init() {}
}
