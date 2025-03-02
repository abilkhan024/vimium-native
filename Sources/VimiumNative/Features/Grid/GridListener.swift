import CoreGraphics
import SwiftUI

// NOTE:
// Trigger grid view on slash when in mouse mode

@MainActor
class GridListener: Listener {
  private var appListener: AppListener?
  private let hintsState = GridHintsState.shared
  private let mouseState = GridMouseState.shared
  private let hintsWindow = GridWindowManager.get(.hints)
  private let mouseWindow = GridWindowManager.get(.mouse)
  private let cursourLen: CGFloat = 10
  private var hintSelected = false
  private var isReopened = false
  private let mappings = AppOptions.shared.keyMappings
  // NOTE: May be adding projection where the next point will land for each
  // direction?
  private var digits = ""

  init() {
    hintsWindow.render(AnyView(GridHintsView())).call()
    mouseWindow.render(AnyView(GridMouseView())).call()
  }

  func matches(_ event: CGEvent) -> Bool {
    return mappings.showGrid.matches(event: event) || mappings.startScroll.matches(event: event)
  }

  func callback(_ event: CGEvent) {
    switch event {
    case _ where mappings.startScroll.matches(event: event):
      guard let screen = NSScreen.main else { return }
      clearHints()
      hintSelected = true
      mouseWindow.front().call()
      moveTo(x: screen.frame.maxX / 2, y: screen.frame.maxY / 2)
    case _ where mappings.showGrid.matches(event: event):
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
    let digits = Int(self.digits) ?? 1
    let isClose = mappings.close.matches(event: event)
    if isClose && hintSelected || isClose && !isReopened {
      return onClose()
    } else if isClose && isReopened {
      clearHints()
      hintSelected = true
    }

    if !hintSelected {
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

    let cusrorOffset = digits * AppOptions.shared.cursorStep
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let scrollSize = AppOptions.shared.scrollSize
    let maxScroll = 99999

    // TODO: Implement sorting to find the mapping that is closest to what user have pressed, and do that action
    switch keyCode {
    case Key.one.rawValue, Key.two.rawValue, Key.three.rawValue, Key.four.rawValue,
      Key.five.rawValue, Key.six.rawValue, Key.seven.rawValue, Key.eight.rawValue,
      Key.nine.rawValue, Key.zero.rawValue:
      guard let char = EventUtils.getEventChar(from: event) else { return }
      self.digits.append(char)
    case _ where mappings.reopenGridView.matches(event: event):
      hintsWindow.front().hideCursor().call()
      hintSelected = false
      isReopened = true
    case _ where mappings.rightClick.matches(event: event):
      EventUtils.rightClick(self.mouseState.position, event.flags)
    case _ where mappings.leftClick.matches(event: event):
      EventUtils.leftClick(self.mouseState.position, event.flags)
      mouseState.dragging = false
    case _ where mappings.scrollLeft.matches(event: event):
      scrollRelative(offsetX: -scrollSize.horizontal * digits)
    case _ where mappings.mouseLeft.matches(event: event):
      moveRelative(offsetX: -cusrorOffset)
    case _ where mappings.scrollRight.matches(event: event):
      scrollRelative(offsetX: scrollSize.horizontal * digits)
    case _ where mappings.mouseRight.matches(event: event):
      moveRelative(offsetX: cusrorOffset)
    case _ where mappings.scrollDown.matches(event: event):
      scrollRelative(offsetY: scrollSize.vertical * digits)
    case _ where mappings.mouseDown.matches(event: event):
      moveRelative(offsetY: cusrorOffset)
    case _ where mappings.scrollUp.matches(event: event):
      scrollRelative(offsetY: -scrollSize.vertical * digits)
    case _ where mappings.mouseUp.matches(event: event):
      moveRelative(offsetY: -cusrorOffset)
    case _ where mappings.scrollPageDown.matches(event: event):
      scrollRelative(offsetY: scrollSize.verticalPage * digits)
    case _ where mappings.scrollPageUp.matches(event: event):
      scrollRelative(offsetY: -scrollSize.verticalPage * digits)
    case _ where mappings.scrollPageDown.matches(event: event):
      scrollRelative(offsetY: scrollSize.verticalPage * digits)
    case _ where mappings.scrollPageUp.matches(event: event):
      scrollRelative(offsetY: -scrollSize.verticalPage * digits)
    case _ where mappings.scrollFullDown.matches(event: event):
      scrollRelative(offsetY: maxScroll)
    case _ where mappings.scrollFullUp.matches(event: event):
      scrollRelative(offsetY: -maxScroll)
    case _ where mappings.enterVisual.matches(event: event):
      mouseState.dragging = !mouseState.dragging
      guard mouseState.dragging else {
        // if let event = CGEvent(source: nil) {
        //   EventUtils.leftMouseUp(event.location)
        // }
        EventUtils.leftMouseUp(self.mouseState.position)
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
    default:
      return
    }

  }

  private func onClose() {
    hintSelected = false
    isReopened = false
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
