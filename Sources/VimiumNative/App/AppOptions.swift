import SwiftUI

// TODO: Read .config later
@MainActor
final class AppOptions {
  static let shared = AppOptions()

  let colors = (bg: Color(red: 230 / 255, green: 210 / 255, blue: 120 / 255), fg: Color.black)

  // INFO: Chars that will be used when generating hints
  let hintChars = "asdfghjklweruio"  // zxcvbnmqpyt

  // INFO: Some websites may use text as buttons, you can enable it to hint the
  // text nodes, but it may slowdown rendering, sometimes significantly
  let hintText = false

  // INFO: Rows and cols dimensions when using, grid mode, change is a
  // trade-off between precision and performance
  let grid = (rows: 36, cols: 36)

  private init() {}
}
