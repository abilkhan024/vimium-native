import CoreGraphics
import SwiftUI

@MainActor
class FzFindWindowManager {
  enum Window: Int { case hints = 0 }
  private static let windows = [WindowBuilder()]
  private init() {}

  static func get(_ win: Window) -> WindowBuilder {
    return self.windows[win.rawValue]
  }
}
