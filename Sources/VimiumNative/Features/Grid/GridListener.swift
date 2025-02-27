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
    hintsWindow.render(AnyView(GridHintsView())).call()
    mouseWindow.render(AnyView(GridMouseView())).call()
  }

  func match(_ event: CGEvent) -> Bool {
    let flags = event.flags
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    return flags.contains(.maskCommand) && flags.contains(.maskShift)
      && (keyCode == Keys.comma.rawValue || keyCode == Keys.j.rawValue)
  }

  func callback(_ event: CGEvent) {
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    switch keyCode {
    case Keys.j.rawValue:
      guard let screen = NSScreen.main else { return }
      clearHints()
      hintSelected = true
      mouseWindow.front().call()
      moveTo(x: screen.frame.maxX / 2, y: screen.frame.maxY / 2)
    case Keys.comma.rawValue:
      let frame = hintsWindow.native().frame
      hintsState.rows = AppOptions.shared.grid.rows
      hintsState.cols = AppOptions.shared.grid.cols
      hintsState.hintWidth = frame.width / CGFloat(hintsState.cols)
      hintsState.hintHeight = frame.height / CGFloat(hintsState.rows)
      hintsState.sequence = HintUtils.getLabels(from: hintsState.rows * hintsState.cols)
      hintsState.matchingCount = hintsState.sequence.count

      if !hintSelected && appListener != nil {
        return
      }
      hintSelected = false
      hintsWindow.front().hideCursor().call()
    default: print("Impossible case")
    }

    if let listener = appListener {
      AppEventManager.remove(listener)
    }
    appListener = AppListener(onEvent: self.onTyping)
    AppEventManager.add(appListener!)
  }

  private func onTyping(_ event: CGEvent) {
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let digits = Int(self.digits) ?? 1

    if !hintSelected {
      switch keyCode {
      case Keys.esc.rawValue:
        return onClose()
      default:
        guard let char = EventUtils.getEventChar(from: event) else { return }
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
          return
        }
      }
    }

    let isShifting = event.flags.contains(.maskShift)
    let cusrorOffset = digits * AppOptions.shared.cursorStep
    switch keyCode {
    case Keys.one.rawValue, Keys.two.rawValue, Keys.three.rawValue, Keys.four.rawValue,
      Keys.five.rawValue, Keys.six.rawValue, Keys.seven.rawValue, Keys.eight.rawValue,
      Keys.nine.rawValue, Keys.zero.rawValue:
      guard let char = EventUtils.getEventChar(from: event) else { return }
      self.digits.append(char)
    case Keys.v.rawValue:
      mouseState.dragging = !mouseState.dragging
      if !mouseState.dragging {
        if let event = CGEvent(source: nil) {
          EventUtils.leftMouseUp(event.location)
        }
        return
      }
      EventUtils.leftMouseDown(self.mouseState.position)

      if AppOptions.shared.jiggleWhenDragging {
        let jiggleStep = 5
        DispatchQueue.main.asyncAfter(deadline: .now()) {
          self.moveRelative(offsetX: jiggleStep)
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.moveRelative(offsetX: -jiggleStep)
          }
        }
      }
    case Keys.dot.rawValue:
      return EventUtils.rightClick(self.mouseState.position)
    case Keys.esc.rawValue:
      return onClose()
    case Keys.h.rawValue:
      if isShifting {
        return scrollRelative(offsetX: -AppOptions.shared.scrollSize.horizontal * digits)
      }
      return moveRelative(offsetX: -cusrorOffset)
    case Keys.l.rawValue:
      if isShifting {
        return scrollRelative(offsetX: AppOptions.shared.scrollSize.horizontal * digits)
      }
      return moveRelative(offsetX: cusrorOffset)
    case Keys.j.rawValue:
      if isShifting {
        return scrollRelative(offsetY: AppOptions.shared.scrollSize.vertical * digits)
      }
      return moveRelative(offsetY: cusrorOffset)
    case Keys.k.rawValue:
      if isShifting {
        return scrollRelative(offsetY: -AppOptions.shared.scrollSize.vertical * digits)
      }
      return moveRelative(offsetY: -cusrorOffset)
    case Keys.d.rawValue:
      return scrollRelative(offsetY: AppOptions.shared.scrollSize.verticalPage * digits)
    case Keys.u.rawValue:
      return scrollRelative(offsetY: -AppOptions.shared.scrollSize.verticalPage * digits)
    case Keys.g.rawValue:
      let direction = isShifting ? 1 : -1
      let maxScroll = 99999
      return scrollRelative(offsetY: direction * maxScroll)
    case Keys.comma.rawValue, Keys.m.rawValue:
      if let event = CGEvent(source: nil) {
        let current = event.location
        EventUtils.leftClick(current, event.flags)
      }
      mouseState.dragging = false
    default:
      return
    }
  }

  private func onClose() {
    hintSelected = false
    mouseState.dragging = false
    clearHints()
    mouseWindow.hide().call()
    if let event = CGEvent(source: nil) {
      EventUtils.leftMouseUp(event.location)
    }
    if let listener = appListener {
      AppEventManager.remove(listener)
      appListener = nil
    }
  }

  private func moveTo(x: CGFloat, y: CGFloat) {
    mouseState.position = CGPointMake(x, y)
    if mouseState.dragging {
      EventUtils.move(mouseState.position, type: .leftMouseDragged)
    } else {
      EventUtils.move(mouseState.position)
    }
  }

  private func scrollRelative(offsetX: Int = 0, offsetY: Int = 0) {
    let deltaY = Int32(offsetY * -1)
    let deltaX = Int32(offsetX * -1)
    EventUtils.scroll(deltaY: deltaY, deltaX: deltaX)
    digits = ""
  }

  private func moveRelative(offsetX: Int = 0, offsetY: Int = 0) {
    mouseState.position.x += CGFloat(offsetX)
    mouseState.position.y += CGFloat(offsetY)
    mouseState.position = EventUtils.normalizePoint(mouseState.position)
    if mouseState.dragging {
      EventUtils.move(mouseState.position, type: .leftMouseDragged)
    } else {
      EventUtils.move(mouseState.position)
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
