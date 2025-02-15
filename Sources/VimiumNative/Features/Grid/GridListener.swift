import CoreGraphics
import SwiftUI

// NOTE:
// In theory Can do much better by changing filter logic to fully precomputing
// result for each char because only 26
// -------------
// or even having window for each valid combination, might be od though,
// and could result slower ui

@MainActor
class GridListener: Listener {
  private var appListener: AppListener?

  private let hintsState = GridHintsState.shared
  private let mouseState = GridMouseState.shared

  private let hintsWindow = GridWindowManager.get(.hints)
  private let mouseWindow = GridWindowManager.get(.mouse)

  private let cursourLen: CGFloat = 10
  private var hintSelected = false

  init() {
    // TODO: make rows and cols customizable currently set as warpd limits
    let frame = hintsWindow.native().frame
    hintsState.rows = 36
    hintsState.cols = 36
    hintsState.hintWidth = frame.width / CGFloat(hintsState.cols)
    hintsState.hintHeight = frame.height / CGFloat(hintsState.rows)
    hintsState.sequence = HintUtils.getLabels(from: hintsState.rows * hintsState.cols)
    hintsState.matchingCount = hintsState.sequence.count
    hintsState.search = ""
    hintSelected = false

    hintsWindow.render(AnyView(GridHintsView())).call()

    mouseWindow.render(AnyView(GridMouseView(length: 10))).call()
  }

  func match(_ event: CGEvent) -> Bool {
    let flags = event.flags
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    return flags.contains(.maskCommand) && flags.contains(.maskShift)
      && keyCode == Keys.comma.rawValue
  }

  func callback(_ event: CGEvent) {
    hintsWindow.front().call()

    if let prev = appListener {
      AppEventManager.remove(prev)
    }
    appListener = AppListener(onEvent: self.onTyping)
    AppEventManager.add(appListener!)
  }

  private func onTyping(_ event: CGEvent) {
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let scale = 5

    if !hintSelected {
      switch keyCode {
      case Keys.esc.rawValue:
        return onClose()
      default:
        guard let char = SystemUtils.getChar(from: event) else { return }
        hintsState.search.append(char)
        hintsState.matchingCount =
          hintsState.sequence.filter { el in el.starts(with: hintsState.search) }.count
        switch hintsState.matchingCount {
        case 0:
          return onClose()
        case 1:
          guard
            let index = HintUtils.getLabels(from: hintsState.rows * hintsState.cols)
              .firstIndex(where: { e in e.starts(with: hintsState.search) })
          else { return clearHints() }

          let col = Double(index).truncatingRemainder(dividingBy: Double(hintsState.cols))
          let row = trunc(Double(index) / Double(hintsState.cols))
          let x: CGFloat = hintsState.hintWidth * col + (hintsState.hintWidth / 2)
          let y: CGFloat = hintsState.hintHeight * row + (hintsState.hintHeight / 2)

          clearHints()
          hintSelected = true
          mouseWindow.front().call()
          return move(x: x, y: y)
        default:
          break
        }
      }
    }

    switch keyCode {
    case Keys.esc.rawValue:
      mouseWindow.hide().call()
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

  private func onClose() {
    hintSelected = false
    clearHints()
    if let listener = appListener {
      AppEventManager.remove(listener)
      appListener = nil
    }
  }

  private func move(x: CGFloat, y: CGFloat) {
    mouseState.position = CGPointMake(x, y)
    // let view = MouseView(position: cursorPos, length: cursourLen)
    SystemUtils.move(mouseState.position)
    // window.render(AnyView(view)).front().call() consume reactive instead
    // TODO: works but i guess must spawn new window and bring to the front for
    // the view instead of resetting
  }

  private func move(offsetX: Int, offsetY: Int, scale: Int) {
    mouseState.position.x += CGFloat(offsetX * scale)
    mouseState.position.y += CGFloat(offsetY * scale)
    // let view = MouseView(position: mouseState.position, length: cursourLen)
    SystemUtils.move(mouseState.position)
    // window.render(AnyView(view)).front().call()
  }

  private func clearHints() {
    hintsWindow.hide().call()
    DispatchQueue.main.async {
      self.hintsState.search = ""
    }
    hintsState.matchingCount = hintsState.sequence.count
  }
}
