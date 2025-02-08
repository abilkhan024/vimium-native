import CoreGraphics
import SwiftUI

@MainActor
class MouseListener: Listener {
  private let window = Window.get()
  private var globalListener: GlobalListener?
  private var cursorPos = CGPointMake(420, 420)

  func match(_ event: CGEvent) -> Bool {
    let flags = event.flags
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    return flags.contains(.maskCommand) && flags.contains(.maskShift)
      && keyCode == Keys.comma.rawValue
  }

  func callback(_ event: CGEvent) {
    // HintsView()
    let view = MouseView(position: cursorPos)
    window.render(AnyView(view)).front().call()

    if let prev = globalListener {
      AppEventManager.remove(prev)
    }
    globalListener = GlobalListener(onEvent: self.onTyping)
    AppEventManager.add(globalListener!)
  }

  private func onClose() {
    if let listener = globalListener {
      AppEventManager.remove(listener)
      globalListener = nil
    }
    window.hide().call()
  }

  private func move(offsetX: Int, offsetY: Int, scale: Int) {
    cursorPos.x += CGFloat(offsetX * scale)
    cursorPos.y += CGFloat(offsetY * scale)
    let view = MouseView(position: cursorPos)
    window.render(AnyView(view)).front().call()
  }

  private func onTyping(_ event: CGEvent) {
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let scale = 10
    switch keyCode {
    case Keys.left.rawValue, Keys.h.rawValue:
      return move(offsetX: -1, offsetY: 0, scale: scale)
    case Keys.l.rawValue, Keys.right.rawValue:
      return move(offsetX: 1, offsetY: 0, scale: scale)
    case Keys.j.rawValue, Keys.down.rawValue:
      return move(offsetX: 0, offsetY: 1, scale: scale)
    case Keys.k.rawValue, Keys.up.rawValue:
      return move(offsetX: 0, offsetY: -1, scale: scale)
    case Keys.dot.rawValue:
      return SystemUtils.click(cursorPos)
    case Keys.esc.rawValue:
      return onClose()
    default:
      return
    }
  }

}
