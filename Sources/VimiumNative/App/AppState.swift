import SwiftUI

struct HintElement: Hashable {
  var id: String
  var axui: AXUIElement
  var content: String?
  var position: CGPoint?
}

@MainActor
final class AppState: ObservableObject {
  var observer: AxObserver?

  static let shared = AppState()
  private init() {}
}
