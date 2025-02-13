import ApplicationServices

@MainActor
class AxApp {
  let pid: pid_t
  let raw: AXUIElement
  private var windows: [AxElement] = []

  init(pid: pid_t) {
    self.pid = pid
    self.raw = AXUIElementCreateApplication(pid)
    self.windows = getWindows().map { e in
      let el = AxElement(e)
      AppState.shared.axMap[e] = el
      return el
    }
  }

  private func getWindows() -> [AXUIElement] {
    var cfWindows: CFTypeRef?
    let winResult = AXUIElementCopyAttributeValue(
      self.raw, kAXWindowsAttribute as CFString, &cfWindows)

    guard winResult == .success, let windows = cfWindows as? [AXUIElement] else {
      print("Failed to get windows with \(winResult)")
      return []
    }

    // NOTE: includes inactive windows
    return windows
  }

  func getVisibleElements() -> [AxElement] {
    var els: [AxElement] = []
    for win in windows {
      els.append(contentsOf: win.getAliveNodes())
    }
    return els
  }

  func revalidateTree() {
    for win in windows {
      win.revalidate()
    }
  }
}
