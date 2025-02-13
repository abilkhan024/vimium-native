import SwiftUI

struct HintElement: Hashable {
  var id: String
  var axui: AXUIElement
  var content: String?
  var position: CGPoint?
}

@MainActor
final class AppState {
  var observer: AxObserver?
  var axMap: [AXUIElement: AxElement] = [:]
  var axApps: [pid_t: AxApp] = [:]

  static let shared = AppState()
  private init() {}
}
