import ApplicationServices
import Cocoa
import SwiftUI

struct TemplateView: View {
  @ObservedObject var state = TemplateState.shared

  var body: some View {
    Text("Template")
  }
}
