import Cocoa
import SwiftUI

struct SettingsView: View {
  @Binding var options: AppOptions

  @State private var debugInfo: String = "Debug output"

  var body: some View {
    VStack(
      spacing: 20,
      content: {
        Text(AppInfo.name)
          .foregroundColor(.blue)
        Text(debugInfo)
          .foregroundColor(.red)
        Toggle(isOn: $options.interactiveOnly) { Text("Interactive only") }
        Button(action: {
          debugInfo = "Trusted \(AXIsProcessTrusted())"
        }) { Text("Debug") }
      }
    )
  }

}
