import SwiftUI

struct HintElement: Hashable {
  var id: String
  var axui: AXUIElement
  var content: String?
  var position: CGPoint?
}

@MainActor
class AppState: ObservableObject {
  private static var shared: AppState?
  @Published var renderedHints: [HintElement] = []

  @Published var sequence: [String] = []
  @Published var search = ""
  @Published var matchingCount = 0
  @Published var rows = 0
  @Published var cols = 0
  @Published var hintWidth: CGFloat = 0
  @Published var hintHeight: CGFloat = 0

  private init() {}

  static func get() -> AppState {
    guard let singletone = shared else {
      let instance = AppState()
      shared = instance
      return instance
    }
    return singletone
  }
}
