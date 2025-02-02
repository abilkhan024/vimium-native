import Cocoa
import SwiftUI

struct SettingsView: View {
  var action: () -> Void

  init(action: @escaping () -> Void) {
    self.action = action
  }

  @State private var debugInfo: String = "Debug output"

  var body: some View {
    VStack(
      spacing: 20,
      content: {
        Text(AppInfo.name)
          .foregroundColor(.blue)
        Text(debugInfo)
          .foregroundColor(.red)
        Button(action: {
          debugInfo = "Trusted \(AXIsProcessTrusted())"
        }) { Text("Debug") }
        Button(action: action) { Text("Action").foregroundColor(.purple) }
      }
    )
  }

}
