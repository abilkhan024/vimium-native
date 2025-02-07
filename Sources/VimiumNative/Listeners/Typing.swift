import CoreGraphics
import SwiftUI

/// Listens to all key strokes
/// must declare some sort of term key
@MainActor
class GlobalListener: Listener {
  let onEvent: (_ event: CGEvent) -> Void

  init(onEvent: @escaping (_ event: CGEvent) -> Void) {
    self.onEvent = onEvent
  }

  func match(_ event: CGEvent) -> Bool {
    return true
  }

  func callback(_ event: CGEvent) {
    onEvent(event)
  }
}
