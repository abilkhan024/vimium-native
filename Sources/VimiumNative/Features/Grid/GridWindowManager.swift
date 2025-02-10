import CoreGraphics
import SwiftUI

@MainActor
class GridWindowManager {
  enum Window: Int {
    case hints = 0
    case mouse = 1
  }

  private static let shared = GridWindowManager()
  private static let windows = [WindowBuilder(), WindowBuilder()]

  private init() {}

  static func get(_ win: Window) -> WindowBuilder {
    return self.windows[win.rawValue]
  }
}
