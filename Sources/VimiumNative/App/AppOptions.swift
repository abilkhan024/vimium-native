import SwiftUI

// INFO: Defaulting to HomeRow alternative
@MainActor
final class AppOptions {
  static let shared = AppOptions()

  // INFO: Colors used for hints
  var colors = (bg: Color(red: 230 / 255, green: 210 / 255, blue: 120 / 255), fg: Color.black)
  // INFO: Chars that will be used when generating hints
  var hintChars = "jklhgasdfweruio"
  // INFO: Some websites may use text as buttons, you can enable it to hint the
  // text nodes, but it may slowdown rendering, sometimes significantly
  // P.s HomeRow doesn't do it, that's why it's false by default
  var hintText = false
  // INFO: How to determine if the element is hintable, .role replicates
  // homerow behaviour, and generally faster, but ignores some elements
  // ----------------------------------------------------------------
  // action: Shows if element provides non ignored action
  // role: Shows if element role is in hardcoded array
  var selection = SelectionType.role
  enum SelectionType {
    case role
    case action
  }
  // INFO: Rows and cols dimensions when using, grid mode, change is a
  // trade-off between precision and performance
  var grid = (rows: 36, cols: 36, fontSize: 14 as CGFloat)

  // INFO: When developing and want to check performance
  let debugPerf = true

  private func proccessOptions(_ options: String) {
    for option in options.components(separatedBy: .newlines) {
      if option.isEmpty || option.starts(with: "#") { continue }
      let optionKeyVal = option.components(separatedBy: "=")
      guard let key = optionKeyVal.first, let value = optionKeyVal.last else { continue }
      switch key {
      case "color_fg":
        if let val = getColor(from: value) {
          self.colors.fg = val
        } else {
          print("color_fg must be a hex string, e.g. #000000")
        }
      case "color_bg":
        if let val = getColor(from: value) {
          self.colors.bg = val
        } else {
          print("color_bg must be a hex string, e.g. #000000")
        }
      case "hint_chars":
        var charsSet = Set<String>()
        let chars = value.filter { char in char.uppercased() != char.lowercased() }
        let seperator = ""
        for char in chars.split(separator: seperator) {
          charsSet.insert(String(char))
        }
        if charsSet.count >= 8 {
          self.hintChars = charsSet.joined(separator: seperator)
        } else {
          print("At least 8 chars must be used for hinting")
        }
      case "grid_rows":

        if let val = Int(value) {
          self.grid.rows = val
        } else {
          print("grid_rows must be a int")
        }
      case "grid_cols":
        if let val = Int(value) {
          self.grid.cols = val
        } else {
          print("grid_cols must be a Int")
        }
      case "grid_font_size":
        if let size = Float(value) {
          self.grid.fontSize = CGFloat(size)
        } else {
          print("grid_font_size must be Float")
        }
      case "hint_selection":
        switch value {
        case "role":
          self.selection = SelectionType.role
        case "action":
          self.selection = SelectionType.action
        default:
          print("hint_selection must be either action or role")
        }
      case "hint_text":
        switch value {
        case "true":
          self.hintText = true
        case "false":
          self.hintText = false
        default:
          print("hint_text must be either true or false")
        }
      default: continue
      }
    }
  }

  private func getColor(from hex: String) -> Color? {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized

    guard hexSanitized.count == 6 || hexSanitized.count == 8 else { return nil }

    var rgbValue: UInt64 = 0
    Scanner(string: hexSanitized).scanHexInt64(&rgbValue)

    let hasAlpha = hexSanitized.count == 8
    let divisor: CGFloat = 255.0
    let red =
      CGFloat((rgbValue & (hasAlpha ? 0xFF00_0000 : 0xFF0000)) >> (hasAlpha ? 24 : 16)) / divisor
    let green =
      CGFloat((rgbValue & (hasAlpha ? 0x00FF_0000 : 0x00FF00)) >> (hasAlpha ? 16 : 8)) / divisor
    let blue =
      CGFloat((rgbValue & (hasAlpha ? 0x0000_FF00 : 0x0000FF)) >> (hasAlpha ? 8 : 0)) / divisor
    let alpha = hasAlpha ? CGFloat(rgbValue & 0x0000_00FF) / divisor : 1.0

    return Color(NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha))
  }

  private init() {
    let filename = "vimium"
    let fileManager = FileManager.default
    let homeDirectoryURL = fileManager.homeDirectoryForCurrentUser
    let configDirectoryURL = homeDirectoryURL.appendingPathComponent(".config", isDirectory: true)
    let filePath = configDirectoryURL.appendingPathComponent(filename).path

    if !fileManager.fileExists(atPath: filePath) {
      print("Config file not found at '\(filePath)', using defaults")
      return
    }

    do {
      let contents = try String(contentsOfFile: filePath, encoding: .utf8)
      proccessOptions(contents)
    } catch {
      print("Error reading file: \(error)")
      return
    }
  }
}
