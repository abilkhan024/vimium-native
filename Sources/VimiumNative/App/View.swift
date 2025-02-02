import SwiftUI

@MainActor
struct AppView: View {
  let listElsAction = ListElementsAction()
  @State var options = AppOptions()

  var body: some View {
    GeometryReader { geometry in
      VStack { SettingsView(options: $options) }
        .onAppear(perform: self.attachListeners)
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
    .edgesIgnoringSafeArea(.all)  // Optional: to ignore safe area
  }

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

  func attachListeners() {
    NSEvent.addGlobalMonitorForEvents(
      matching: .keyDown,
      handler: { (event) in
        if !event.modifierFlags.contains([.command, .shift]) || event.keyCode != 47 {
          return
        }
        print("Interactive only \(self.options.interactiveOnly)")
        self.listAll()
      })
  }
}
