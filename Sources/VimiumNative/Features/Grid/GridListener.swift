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
  private let maxScroll = 99999
  private let scrollSize = AppOptions.shared.scrollSize
  private var dblClickTimer: DispatchSourceTimer?
  private var clickCount = 0

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

  private lazy var keyToPrimeAction: [KeyMapping: (_: CGEvent) -> Bool] = [
    mappings.startScroll: { _ in
      guard let app = NSWorkspace.shared.frontmostApplication else { return true }
      self.clearHints()
      self.hintSelected = true
      self.mouseWindow.front().call()
      let pid = app.processIdentifier
      let appEl = AXUIElementCreateApplication(app.processIdentifier)
      var winRef: CFTypeRef?
      let winResult = AXUIElementCopyAttributeValue(
        appEl, kAXMainWindowAttribute as CFString, &winRef)

      guard winResult == .success, let mainWindow = winRef as! AXUIElement? else { return true }
      let windowEl = AxElement(mainWindow)

      guard let bound = windowEl.bound else {
        return true
      }
      self.mouseState.focusedRect = bound
      self.moveTo(x: bound.midX, y: bound.midY)
      return false
    },
    mappings.showGrid: { _ in
      let frame = self.hintsWindow.native().frame
      self.hintsState.rows = AppOptions.shared.grid.rows
      self.hintsState.cols = AppOptions.shared.grid.cols
      self.hintsState.hintWidth = frame.width / CGFloat(self.hintsState.cols)
      self.hintsState.hintHeight = frame.height / CGFloat(self.hintsState.rows)
      self.hintsState.sequence = HintUtils.getLabels(
        from: self.hintsState.rows * self.hintsState.cols)
      self.hintsState.matchingCount = self.hintsState.sequence.count

      if !self.hintSelected && self.appListener != nil {
        return true
      }
      self.hintSelected = false
      self.hintsWindow.front().hideCursor().call()
      return false
    },

  ]

  private lazy var keyToAction: [KeyMapping: (_: CGEvent) -> Void] = [
    mappings.reopenGridView: { _ in
      self.hintsWindow.front().hideCursor().call()
      self.hintSelected = false
      self.isReopened = true
    },
    mappings.rightClick: { event in
      EventUtils.rightClick(self.mouseState.position, event.flags)
    },
    mappings.leftClick: { event in
      self.dblClickTimer?.cancel()
      self.dblClickTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
      self.dblClickTimer?.schedule(deadline: .now() + NSEvent.doubleClickInterval)
      self.dblClickTimer?.setEventHandler {
        self.clickCount = 0
      }
      self.clickCount += 1
      self.dblClickTimer?.resume()

      let safeCount = self.clickCount == 0 ? 1 : self.clickCount
      EventUtils.leftClick(self.mouseState.position, event.flags, count: safeCount)
      self.mouseState.dragging = false
    },
    mappings.scrollLeft: { _ in
      self.scrollRelative(offsetX: -self.scrollSize.horizontal * (Int(self.digits) ?? 1))
    },
    mappings.mouseLeft: { _ in
      let cusrorOffset = (Int(self.digits) ?? 1) * AppOptions.shared.cursorStep
      self.moveRelative(offsetX: -cusrorOffset)
    },
    mappings.scrollRight: { _ in
      self.scrollRelative(offsetX: self.scrollSize.horizontal * (Int(self.digits) ?? 1))
    },
    mappings.mouseRight: { _ in
      let cusrorOffset = (Int(self.digits) ?? 1) * AppOptions.shared.cursorStep
      self.moveRelative(offsetX: cusrorOffset)
    },
    mappings.scrollDown: { _ in
      self.scrollRelative(offsetY: self.scrollSize.vertical * (Int(self.digits) ?? 1))
    },
    mappings.mouseDown: { _ in
      let cusrorOffset = (Int(self.digits) ?? 1) * AppOptions.shared.cursorStep
      self.moveRelative(offsetY: cusrorOffset)
    },
    mappings.scrollUp: { _ in
      self.scrollRelative(offsetY: -self.scrollSize.vertical * (Int(self.digits) ?? 1))
    },
    mappings.mouseUp: { _ in
      let cusrorOffset = (Int(self.digits) ?? 1) * AppOptions.shared.cursorStep
      self.moveRelative(offsetY: -cusrorOffset)
    },
    mappings.scrollPageDown: { _ in
      self.scrollRelative(offsetY: self.scrollSize.verticalPage * (Int(self.digits) ?? 1))
    },
    mappings.scrollPageUp: { _ in
      self.scrollRelative(offsetY: -self.scrollSize.verticalPage * (Int(self.digits) ?? 1))
    },
    mappings.scrollFullDown: { _ in
      self.scrollRelative(offsetY: self.maxScroll)
    },
    mappings.scrollFullUp: { _ in
      self.scrollRelative(offsetY: -self.maxScroll)
    },
    mappings.enterVisual: { _ in
      self.mouseState.dragging.toggle()
      guard self.mouseState.dragging else {
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
    },
  ]

  func callback(_ event: CGEvent) {
    guard
      let bestActionKey = keyToPrimeAction.keys.max(by: { a, b in
        a.getScore(event: event) < b.getScore(event: event)
      }),
      bestActionKey.matches(event: event),
      let bestAction = keyToPrimeAction[bestActionKey]
    else { return }
    InputSourceUtils.selectAbc()

    if bestAction(event) {
      return
    }

    if let listener = appListener {
      AppEventManager.remove(listener)
    }
    appListener = AppListener(onEvent: self.onTyping)
    AppEventManager.add(appListener!)
  }

  private func onTyping(_ event: CGEvent) {
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
        self.mouseState.focusedRect = nil
        return moveTo(x: x, y: y)
      default:
        return
      }
    }

    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    switch keyCode {
    case Key.one.rawValue, Key.two.rawValue, Key.three.rawValue, Key.four.rawValue,
      Key.five.rawValue, Key.six.rawValue, Key.seven.rawValue, Key.eight.rawValue,
      Key.nine.rawValue, Key.zero.rawValue:
      guard let char = EventUtils.getEventChar(from: event) else { return }
      self.digits.append(char)
    default:
      guard
        let bestActionKey = keyToAction.keys.max(by: { a, b in
          a.getScore(event: event) < b.getScore(event: event)
        }),
        bestActionKey.matches(event: event),
        let bestAction = keyToAction[bestActionKey]
      else { return }
      bestAction(event)
    }
  }

  private func onClose() {
    InputSourceUtils.restoreCurrent()
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
