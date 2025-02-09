import CoreGraphics
import SwiftUI

@MainActor
class MouseListener: Listener {
  private let window = Window.get()
  private var globalListener: GlobalListener?
  private var cursorPos = CGPointMake(420, 420)
  private let hintWidth: CGFloat = 36
  private let hintHeight: CGFloat = 20

  // Must be valid logic instead
  private let rows = Int(ceil(Window.get().native().frame.height / 20)) - 14
  private let cols = Int(ceil(Window.get().native().frame.width / 36)) - 8

  private let cursourLen: CGFloat = 10
  private var selected = false
  private var input = ""

  func match(_ event: CGEvent) -> Bool {
    let flags = event.flags
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    return flags.contains(.maskCommand) && flags.contains(.maskShift)
      && keyCode == Keys.comma.rawValue
  }

  func callback(_ event: CGEvent) {
    renderHintsGrid()
    selected = false

    if let prev = globalListener {
      AppEventManager.remove(prev)
    }
    globalListener = GlobalListener(onEvent: self.onTyping)
    AppEventManager.add(globalListener!)
  }

  private func renderHintsGrid() {
    let seq = HintUtils.genLabels(from: rows * cols)
    let matching = seq.filter { el in el.starts(with: input) }.count

    let view = ZStack {
      Grid {
        ForEach(0..<self.rows, id: \.self) { i in
          GridRow {
            ForEach(0..<self.cols, id: \.self) { j in
              let isMatching = seq[i * self.cols + j].starts(with: self.input)
              let opacity = isMatching && matching == 1 ? 1 : !isMatching ? 0 : 0.4
              Text(seq[i * self.cols + j])
                .font(.system(size: 16))
                .foregroundColor(.red)
                .frame(width: self.hintWidth, height: self.hintHeight)
                .background(.black)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(.red, lineWidth: 3))
                .cornerRadius(4)
                .opacity(opacity)
            }
          }
        }
      }
    }
    window.render(AnyView(view)).front().call()
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
    input = ""
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
          let index = HintUtils.genLabels(from: rows * cols)
            .firstIndex(where: { e in e.starts(with: self.input) })
        else { return selectAndClear() }

        /// why these magic values, no fucking idea just hacked through it
        let col = Double(index).truncatingRemainder(dividingBy: Double(cols))
        let row = trunc(Double(index) / Double(rows))
        let height = Window.get().native().frame.height
        let width = Window.get().native().frame.width
        let cellWidth = width / CGFloat(cols)
        let cellHeight = height / CGFloat(cols)
        let x: CGFloat = cellWidth * col + (cellWidth / 2)
        let y: CGFloat = cellHeight * row + (cellHeight / 2)

        selectAndClear()
        return move(x: x, y: y)
      default:
        guard let char = SystemUtils.getChar(from: event) else { return }
        input.append(char)
        return renderHintsGrid()
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
