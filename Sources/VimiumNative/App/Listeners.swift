import SwiftUI

@MainActor
class AppListeners {
  let listElsAction = ListElementsAction()

  func listAll() {
    guard let hintsView = self.listElsAction.exec() else {
      return print("Failed to get HintsView")
    }

    let overlayWindow = Window(view: AnyView(hintsView)).transparent().front().make()
    var monitor: Any?
    monitor = NSEvent.addGlobalMonitorForEvents(
      matching: .keyDown,
      handler: { (event) in
        if !event.modifierFlags.contains([.command, .shift]) || event.keyCode != 43 {
          return
        }
        if let mon = monitor {
          overlayWindow.close()
          NSEvent.removeMonitor(mon)
        }
      })
  }

  func listen() {
    NSEvent.addGlobalMonitorForEvents(
      matching: .keyDown,
      handler: { (event) in
        if !event.modifierFlags.contains([.command, .shift]) || event.keyCode != 47 {
          return
        }
        self.listAll()
      })
  }
}
