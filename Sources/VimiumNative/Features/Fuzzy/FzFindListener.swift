import CoreGraphics
@preconcurrency import SwiftUI

@Sendable
private func dfs(
  _ el: AxElement, _ parents: [AxElement], _ wg: DispatchGroup, _ frame: AxElement.Frame,
  _ execQueue: DispatchQueue, _ flags: AxElement.Flags,
  _ onFound: @escaping @Sendable (_: AxElement) -> Void
) {
  let visible = el.getIsVisible(frame, parents, flags)
  if visible == false {
    return
  }
  var childrenRef: CFTypeRef?

  let childParents = parents + [el]
  let childResult = AXUIElementCopyAttributeValue(
    el.raw, kAXChildrenAttribute as CFString, &childrenRef)
  if childResult == .success, let children = childrenRef as? [AXUIElement] {
    for child in children {
      wg.enter()
      execQueue.async {
        dfs(AxElement(child), childParents, wg, frame, execQueue, flags, onFound)
        wg.leave()
      }
    }
  }

  if el.getIsHintable(flags) {
    onFound(el)
  }
}

@MainActor
class FzFindListener: Listener {
  private let hintsWindow = FzFindWindowManager.get(.hints)
  private var appListener: AppListener?
  private let state = FzFindState.shared
  private var hints: [AxElement] = []
  private var tmp: WindowBuilder?
  private let execQueue = DispatchQueue.global(qos: .userInteractive)
  private var systemMenuItems: [AxElement] = []

  init() {
    hintsWindow.render(AnyView(FzFindHintsView())).call()
    if AppOptions.shared.systemMenuPoll != 0 {
      Timer.scheduledTimer(
        withTimeInterval: Double(AppOptions.shared.systemMenuPoll), repeats: true,
        block: { _ in
          DispatchQueue.main.async {
            self.pollSysMenu()
          }
        })
      DispatchQueue.main.async {
        self.pollSysMenu()
      }
    }
  }

  private func getAxFlags() -> AxElement.Flags {
    return AxElement.Flags(
      traverseHidden: AppOptions.shared.traverseHidden,
      hintText: AppOptions.shared.hintText,
      roleBased: AppOptions.shared.selection == .role
    )

  }

  private func getAxFrame(_ screen: NSScreen) -> AxElement.Frame {
    return AxElement.Frame(height: screen.frame.height, width: screen.frame.width)
  }

  private func pollSysMenu() {
    guard let screen = NSScreen.main else { return }
    let frame = getAxFrame(screen)
    let flags = getAxFlags()
    nonisolated(unsafe) var result: [AxElement] = []
    let queue = DispatchQueue(label: "result-append-queue", attributes: .concurrent)

    let onFound: @Sendable (_: AxElement) -> Void = { e in
      queue.async(flags: .barrier) { result.append(e) }
    }

    let maxX = screen.frame.maxX
    let wg = DispatchGroup()

    var min = maxX / 2
    let max = maxX
    let step = 11.0
    let menuBarY: Float = 11.0

    var positionsToCheck: [Float] = []
    while min + step < max {
      positionsToCheck.append(Float(min + step / 2))
      min += step
    }

    let sys = AXUIElementCreateSystemWide()

    for pos in positionsToCheck {
      wg.enter()
      execQueue.async {
        var el: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(sys, pos, menuBarY, &el)
        if result == .success, let axui = el as AXUIElement? {
          dfs(AxElement(axui), [], wg, frame, self.execQueue, flags, onFound)
        }
        wg.leave()
      }
    }
    wg.wait()
    self.systemMenuItems = result
  }

  // Limitations:
  // 1. Must get system from top right half using func above
  private func getVisibleEls() -> [AxElement] {
    let wg = DispatchGroup()

    guard let app = NSWorkspace.shared.frontmostApplication, let screen = NSScreen.main else {
      return []
    }
    let frame = getAxFrame(screen)
    let flags = getAxFlags()

    let pid = app.processIdentifier
    let appEl = AXUIElementCreateApplication(pid)

    if CommandLine.arguments.contains("eui-app-set") {
      AXUIElementSetAttributeValue(appEl, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)
    }
    var winRef: CFTypeRef?
    let winResult = AXUIElementCopyAttributeValue(
      appEl, kAXMainWindowAttribute as CFString, &winRef)

    guard winResult == .success, let mainWindow = winRef as! AXUIElement? else { return [] }

    nonisolated(unsafe) var result = systemMenuItems
    let queue = DispatchQueue(label: "result-append-queue", attributes: .concurrent)
    let onFound: @Sendable (_: AxElement) -> Void = { e in
      queue.async(flags: .barrier) { result.append(e) }
    }

    wg.enter()
    execQueue.async {
      var menuBar: AnyObject?

      let result = AXUIElementCopyAttributeValue(
        appEl, kAXMenuBarAttribute as CFString, &menuBar)

      if result == .success, let menuBarElement = menuBar as! AXUIElement? {
        dfs(AxElement(menuBarElement), [], wg, frame, self.execQueue, flags, onFound)
      }
      wg.leave()
    }

    wg.enter()
    execQueue.async {
      dfs(AxElement(mainWindow), [], wg, frame, self.execQueue, flags, onFound)
      wg.leave()
    }
    wg.wait()

    return result
  }

  func match(_ event: CGEvent) -> Bool {
    let flags = event.flags
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    return flags.contains(.maskCommand) && flags.contains(.maskShift)
      && keyCode == Keys.dot.rawValue
  }

  func removeDuplicates(from els: [AxElement], within radius: Double) -> [AxElement] {
    var uniqueEls: [AxElement] = []

    for el in els {
      guard let point = el.point else { continue }
      var isDuplicate = false
      for unique in uniqueEls {
        let existingPoint = unique.point
        let dx = point.x - existingPoint!.x
        let dy = point.y - existingPoint!.y
        let distanceSquared = dx * dx + dy * dy
        if distanceSquared <= radius * radius {
          isDuplicate = true
          break
        }
      }
      if !isDuplicate {
        uniqueEls.append(el)
      }
    }

    return uniqueEls
  }

  func callback(_ event: CGEvent) {
    if self.appListener != nil {
      return
    }
    state.search = ""
    self.hintsWindow.front().hideCursor().call()
    state.loading = true
    self.appListener = AppListener(onEvent: self.onTyping)
    AppEventManager.add(self.appListener!)

    DispatchQueue.main.async {
      let start = DispatchTime.now().uptimeNanoseconds
      let hints = self.removeDuplicates(from: self.getVisibleEls(), within: 16)
      // if AppOptions.shared.debugPerf {
      print("Generated in \(DispatchTime.now().uptimeNanoseconds - start) for \(hints.count)")
      // }
      self.hints = hints
      self.state.hints = self.hints
      self.state.texts = HintUtils.getLabels(from: self.state.hints.count)
      self.state.loading = false
    }
  }

  private func onClose() {
    hintsWindow.hide().call()
    DispatchQueue.main.async {
      if let listener = self.appListener {
        AppEventManager.remove(listener)
        self.appListener = nil
      }
      self.state.hints = []
      self.state.search = ""
    }
  }

  private func onTyping(_ event: CGEvent) {
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    switch keyCode {
    case Keys.slash.rawValue:
      return  // FZF mode incoming
    case Keys.esc.rawValue:
      return onClose()
    case Keys.semicolon.rawValue:
      self.state.zIndexInverted = !self.state.zIndexInverted
    default:
      guard let char = EventUtils.getEventChar(from: event) else { return }
      state.search.append(char)
      if self.state.texts.firstIndex(where: { str in str.starts(with: state.search) }) == nil {
        return onClose()
      }

      if let idx = self.state.texts.firstIndex(of: state.search), idx < self.hints.count,
        let point = self.hints[idx].point
      {
        EventUtils.leftClick(point, event.flags)
        onClose()
      }
    }
  }
}
