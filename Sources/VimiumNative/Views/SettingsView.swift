import Cocoa
import SwiftUI

struct SettingsView: View {
  var onMount: () -> Void

  init(onMount: @escaping () -> Void) {
    self.onMount = onMount
  }

  var body: some View {
    VStack(content: {
      Text("Hello from SwiftUI")
        .foregroundColor(.blue)
      Text("Hello from SwiftUI v2")
        .foregroundColor(.blue)
    }).onAppear(perform: self.onMount)
  }

}
