import CoreGraphics
import SwiftUI

@MainActor
class TemplateListener: Listener {
  init() {
  }

  func matches(_ event: CGEvent) -> Bool {
    return false
  }

  func callback(_ event: CGEvent) {

  }

  func abort() {}
}
