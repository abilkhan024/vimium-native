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
