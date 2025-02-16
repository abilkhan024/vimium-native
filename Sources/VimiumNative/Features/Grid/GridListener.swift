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
  // NOTE: May be adding projection where the next point will land for each
  // direction?
  private var digits = ""

  init() {
    let frame = hintsWindow.native().frame
    hintsState.rows = AppOptions.shared.grid.rows
    hintsState.cols = AppOptions.shared.grid.cols
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
    NSCursor.hide()
    if appListener != nil {
      return
    }
    hintsWindow.front().call()

    appListener = AppListener(onEvent: self.onTyping)
    AppEventManager.add(appListener!)
  }

  private func onTyping(_ event: CGEvent) {
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let digits = Int(self.digits) ?? 1
    let scale = digits * 5

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
          return moveTo(x: x, y: y)
        default:
          break
        }
      }
    }

    let isShifting = event.flags.contains(.maskShift)
    switch keyCode {
    case Keys.one.rawValue, Keys.two.rawValue, Keys.three.rawValue, Keys.four.rawValue,
      Keys.five.rawValue, Keys.six.rawValue, Keys.seven.rawValue, Keys.eight.rawValue,
      Keys.nine.rawValue, Keys.zero.rawValue:
      guard let char = SystemUtils.getChar(from: event) else { return }
      self.digits.append(char)
    case Keys.v.rawValue:
      return SystemUtils.mouseDown(self.mouseState.position)
    case Keys.esc.rawValue:
      mouseWindow.hide().call()
      return onClose()
    case Keys.h.rawValue:
      return moveRelative(isShifting: isShifting, offsetX: -1, offsetY: 0, scale: scale)
    case Keys.l.rawValue:
      return moveRelative(isShifting: isShifting, offsetX: 1, offsetY: 0, scale: scale)
    case Keys.j.rawValue:
      return moveRelative(isShifting: isShifting, offsetX: 0, offsetY: 1, scale: scale)
    case Keys.k.rawValue:
      return moveRelative(isShifting: isShifting, offsetX: 0, offsetY: -1, scale: scale)
    case Keys.m.rawValue:
      return SystemUtils.click()
    default:
      return
    }
  }

  private func onClose() {
    hintSelected = false
    clearHints()
    if let event = CGEvent(source: nil) {
      SystemUtils.mouseUp(event.location)
    }
    if let listener = appListener {
      AppEventManager.remove(listener)
      appListener = nil
    }
  }

  private func moveTo(x: CGFloat, y: CGFloat) {
    mouseState.position = CGPointMake(x, y)
    SystemUtils.move(mouseState.position)
  }

  private func moveRelative(isShifting: Bool, offsetX: Int, offsetY: Int, scale: Int) {
    if isShifting {
      let deltaY = Int32(offsetY * -1 * scale)
      let deltaX = Int32(offsetX * -1 * scale)
      SystemUtils.scroll(deltaY: deltaY, deltaX: deltaX)
    } else {
      mouseState.position.x += CGFloat(offsetX * scale)
      mouseState.position.y += CGFloat(offsetY * scale)
      mouseState.position = SystemUtils.normalizePoint(mouseState.position)
      SystemUtils.move(mouseState.position)
    }
    digits = ""
  }

  private func clearHints() {
    hintsWindow.hide().call()
    DispatchQueue.main.async {
      self.hintsState.search = ""
    }
    hintsState.matchingCount = hintsState.sequence.count
  }
}
