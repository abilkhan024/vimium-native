import SwiftUI

// TODO: Read .config later
@MainActor
final class AppOptions {
  static let shared = AppOptions()

  let colors = (bg: Color.gray, fg: Color.black)

  // INFO: Chars that will be used when generating hints
  let hintChars = "asdfghjklweruio"  // zxcvbnmqpyt

  // INFO: Some may use text as buttons, you can enable it to hint the text
  // nodes, but it may slowdown rendering, sometimes significantly
  let hintText = true

  private init() {}
}
