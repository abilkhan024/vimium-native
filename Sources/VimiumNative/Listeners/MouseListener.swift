import CoreGraphics
import SwiftUI

@MainActor
class MouseListener: Listener {
  private let window = Window.get()
  private let state = AppState.get()
  private var globalListener: GlobalListener?
  private var cursorPos = CGPointMake(420, 420)

  private let cursourLen: CGFloat = 10
  private var selected = false

  func match(_ event: CGEvent) -> Bool {
    let flags = event.flags
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    return flags.contains(.maskCommand) && flags.contains(.maskShift)
      && keyCode == Keys.comma.rawValue
  }

  func callback(_ event: CGEvent) {
    let height = Window.get().native().frame.height
    let width = Window.get().native().frame.width
    // TODO: make customizable currently set as warpd limits
    state.rows = 26
    state.cols = 26
    state.hintWidth = width / CGFloat(state.cols)
    state.hintHeight = height / CGFloat(state.rows)
    state.sequence = HintUtils.genLabels(from: state.rows * state.cols)
    state.matchingCount = state.sequence.count
    state.search = ""
    selected = false
    window.render(AnyView(GridView())).front().call()

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
    selectAndClear()
  }

  private func move(x: CGFloat, y: CGFloat) {
    let pos = CGPointMake(x, y)
    cursorPos = pos
    let view = MouseView(position: cursorPos, length: cursourLen)
    SystemUtils.move(cursorPos)
    window.render(AnyView(view)).front().call()
  }

  private func move(offsetX: Int, offsetY: Int, scale: Int) {
    cursorPos.x += CGFloat(offsetX * scale)
    cursorPos.y += CGFloat(offsetY * scale)
    let view = MouseView(position: cursorPos, length: cursourLen)
    SystemUtils.move(cursorPos)
    window.render(AnyView(view)).front().call()
  }

  private func selectAndClear() {
    selected = true
    state.search = ""
    window.clear().hide().call()
  }

  private func onTyping(_ event: CGEvent) {
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let scale = 20

    if !selected {
      switch keyCode {
      case Keys.esc.rawValue:
        return onClose()
      case Keys.enter.rawValue:
        guard
          let index = HintUtils.genLabels(from: state.rows * state.cols)
            .firstIndex(where: { e in e.starts(with: self.state.search) })
        else { return selectAndClear() }

        let col = Double(index).truncatingRemainder(dividingBy: Double(state.cols))
        let row = trunc(Double(index) / Double(state.cols))
        let x: CGFloat = state.hintWidth * col + (state.hintWidth / 2)
        let y: CGFloat = state.hintHeight * row + (state.hintHeight / 2)

        selectAndClear()
        return move(x: x, y: y)
      case Keys.backspace.rawValue:
        self.state.search = String(self.state.search.dropLast())
        state.matchingCount = state.sequence.filter { el in el.starts(with: state.search) }.count
        return
      default:
        guard let char = SystemUtils.getChar(from: event) else { return }
        state.search.append(char)
        state.matchingCount = state.sequence.filter { el in el.starts(with: state.search) }.count
        return
      }
    }

    switch keyCode {
    case Keys.esc.rawValue:
      return onClose()
    case Keys.left.rawValue, Keys.h.rawValue:
      return move(offsetX: -1, offsetY: 0, scale: scale)
    case Keys.l.rawValue, Keys.right.rawValue:
      return move(offsetX: 1, offsetY: 0, scale: scale)
    case Keys.j.rawValue, Keys.down.rawValue:
      return move(offsetX: 0, offsetY: 1, scale: scale)
    case Keys.k.rawValue, Keys.up.rawValue:
      return move(offsetX: 0, offsetY: -1, scale: scale)
    case Keys.m.rawValue:
      return SystemUtils.click()
    default:
      return
    }
  }

}
