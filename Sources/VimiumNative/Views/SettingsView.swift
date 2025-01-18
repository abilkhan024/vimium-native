import Cocoa
import SwiftUI

struct SettingsView: View {
  var action: () -> Void

  init(action: @escaping () -> Void) {
    self.action = action
  }

  @State private var debugInfo: String = "Debug output"

  var body: some View {
    let url = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

    VStack(
      spacing: 20,
      content: {
        Text("Hello from SwiftUI")
          .foregroundColor(.blue)
        Text(debugInfo)
          .foregroundColor(.red)
        Button(action: {
          NSWorkspace.shared.open(URL(string: url)!)
        }) { Text("Allow") }
        Button(action: {
          debugInfo = "Trusted \(AXIsProcessTrusted())"
        }) { Text("Debug") }
        Button(action: action) { Text("Action").foregroundColor(.purple) }
      }
    )
  }

}
