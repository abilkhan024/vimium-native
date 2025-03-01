import SwiftUI

// TODO: May be allow changing them on the fly via some shortcut
// INFO: Defaulting to HomeRow alternative
@MainActor
final class AppOptions {
  static let shared = AppOptions()

  struct ParseError: Error {
    let message: String
  }

  // EXAMPLE:
  //   # Color by default
  //   mouse_color_normal=#ff0000
  //   # Color when dragging
  //   mouse_color_visual=#000000
  //   # Color of the outline when in mouse mode
  //   mouse_outline_color=#ff0000
  //   # Hides Outline when set to 0
  //   mouse_outline_width=0
  //   # Virtual circle cursor size
  //   mouse_size=10.0
  // INFO: Mouse params when entering grid mode
  var mouse = (
    colorNormal: Color.red, colorVisual: Color.blue, outlineColor: Color.blue,
    outlineWidth: CGFloat(8.0), size: CGFloat(10.0)
  )

  // EXAMPLE:
  //   hint_font_size=20.0
  // INFO: Font size of the hint label
  var hintFontSize: CGFloat = 14.0

  // EXAMPLE:
  //   hint_triangle_height=8.0
  // INFO: Height of the triangle indicating point that will be clicked
  var hintTriangleHeight: CGFloat = 6.0

  // EXAMPLE:
  //   scroll_size_vertical=20
  //   scroll_size_horizontal=80
  //   scroll_size_vertical_page=200
  // INFO: Scroll scale vertical when using jk, horizontal for hl, verticalPage: du
  var scrollSize = (vertical: 5, horizontal: 40, verticalPage: 100)

  // EXAMPLE:
  //   cursor_step=20
  // INFO: Cursor move size
  var cursorStep = 5

  // EXAMPLE:
  //   traverse_hidden=true
  // INFO: Traverse the children of the node if the node has dimensions of <=1
  // Generally advised against, because slows down perf
  var traverseHidden = false

  // EXAMPLE:
  //   system_menu_poll=0
  // INFO: Interval for system menu poll in seconds 0 doesn't poll system menu
  // therefore won't show it, min value that won't degrade performance is 10
  var systemMenuPoll = 10

  // EXAMPLE:
  //   color_bg=#ff0000
  //   color_fg=#ff0000
  // INFO: Colors used for hints
  var colors = (bg: Color(red: 230 / 255, green: 210 / 255, blue: 120 / 255), fg: Color.black)

  // EXAMPLE:
  //   hint_chars=jklhgasdfweruio
  // INFO: Chars that will be used when generating hints
  var hintChars = "jklhgasdfweruio"

  // EXAMPLE:
  //   hint_text=false
  // INFO: Some websites may use text as buttons, you can enable it to hint the
  // text nodes, but it may slowdown rendering, sometimes significantly
  // P.s HomeRow doesn't do it, that's why it's false by default
  var hintText = false

  // EXAMPLE:
  //   hint_selection=action
  //   # Possible values action|role
  // ----------------------------------------------------------------
  // INFO: How to determine if the element is hintable, .role replicates
  // homerow behaviour, and generally faster, but ignores some elements
  // ----------------------------------------------------------------
  // action: Shows if element provides non ignored action
  // role: Shows if element role is in hard-coded array
  var selection = SelectionType.role
  enum SelectionType {
    case role
    case action
  }

  // EXAMPLE:
  //   grid_rows=42
  //   grid_cols=48
  //   grid_font_size=12
  // INFO: Rows and cols dimensions when using, grid mode, change is a
  // trade-off between precision and performance
  var grid = (rows: 36, cols: 36, fontSize: CGFloat(14.0))

  // EXAMPLE:
  //   jiggle_when_dragging=true
  // INFO: Sometimes macos refuses to register drag when you immediately jump
  // between labels, you can enable this flag that will jiggle once you start
  // dragging
  var jiggleWhenDragging = false

  // EXAMPLE:
  //   debug_perf=true
  // INFO: When developing and want to check performance
  var debugPerf = false

  var keyMappings = (
    showHints: KeyMapping(key: .dot, modifiers: [.command, .shift]),  // Validate has modifiers
    showGrid: KeyMapping(key: .comma, modifiers: [.command, .shift]),  // Validate has modifiers
    startScroll: KeyMapping(key: .j, modifiers: [.command, .shift]),  // Validate has modifiers
    close: KeyMapping(key: .esc),  // Validate not a hint char

    enterSearchMode: KeyMapping(key: .slash),  // Validate not a hint char
    nextSearchOccurence: KeyMapping(key: .tab),  // Validate is non printable char
    prevSearchOccurence: KeyMapping(key: .tab, modifiers: [.shift]),  // Validate is non printable char
    selectOccurence: KeyMapping(key: .enter),  // Validate is non printable char
    dropLastSearchChar: KeyMapping(key: .backspace),  // Validate is non printable char
    toggleZIndex: KeyMapping(key: .semicolon),  // Validate not a hint char

    mouseLeft: KeyMapping(key: .h),
    mouseDown: KeyMapping(key: .j),
    mouseUp: KeyMapping(key: .k),
    mouseRight: KeyMapping(key: .l),

    scrollLeft: KeyMapping(key: .h, modifiers: [.shift]),
    scrollDown: KeyMapping(key: .j, modifiers: [.shift]),
    scrollUp: KeyMapping(key: .k, modifiers: [.shift]),
    scrollRight: KeyMapping(key: .l, modifiers: [.shift]),

    scrollPageDown: KeyMapping(key: .d),
    scrollPageUp: KeyMapping(key: .u),
    scrollFullDown: KeyMapping(key: .g, modifiers: [.shift]),
    scrollFullUp: KeyMapping(key: .g),

    enterVisual: KeyMapping(key: .v),
    // Triggers once first hint is selected
    reopenGridView: KeyMapping(key: .slash),
    rightClick: KeyMapping(key: .dot),
    leftClick: KeyMapping(key: .enter)
  )

  enum KeyValidationFlag {
    case requireModifiers
    case charOnly
    case nonPrintableChar
    case notInHintChars
  }

  private func parseKeyMapping(from: String, field: String, flags: [KeyValidationFlag] = [])
    throws -> KeyMapping
  {
    guard let mapping = KeyMapping.create(from: from) else {
      throw ParseError(message: "\(field) is not a valid key mapping")
    }
    if flags.contains(.requireModifiers) && mapping.modifiers.isEmpty {
      throw ParseError(message: "\(field) must use modifiers")
    }
    let keyString = KeyMapping.itoa(key: mapping.key.rawValue)!
    let keyChar = keyString.first!
    if flags.contains(.charOnly) && String(keyChar) == keyChar.uppercased() {
      throw ParseError(message: "\(field) must only use ascii chars")
    } else if flags.contains(.notInHintChars) && hintChars.contains(keyChar) {
      throw ParseError(message: "\(field) can only use chars that are not used in hint_chars")
    } else if flags.contains(.nonPrintableChar) && !mapping.isNonPrintable() {
      throw ParseError(message: "\(field) can only use non printable key")
    }
    return mapping
  }

  private func parseCgFloat(value: String, field: String) throws -> CGFloat {
    guard let value = Float(value) else {
      throw ParseError(message: "\(field) must be float")
    }
    return CGFloat(value)
  }

  private func parseInt(value: String, field: String) throws -> Int {
    guard let value = Int(value) else { throw ParseError(message: "\(field) must be int") }
    return value
  }

  private func parseBool(value: String, field: String) throws -> Bool {
    switch value {
    case "true":
      return true
    case "false":
      return false
    default:
      throw ParseError(message: "\(field) must be either true or false")
    }
  }

  private func proccessOptions(_ options: String) throws {
    for option in options.components(separatedBy: .newlines) {
      if option.isEmpty || option.starts(with: "#") { continue }
      let optionKeyVal = option.components(separatedBy: "=")
      guard let key = optionKeyVal.first, let value = optionKeyVal.last else { continue }
      switch key {
      case "mouse_outline_width":
        try self.mouse.outlineWidth = parseCgFloat(value: value, field: key)
      case "mouse_outline_color":
        try self.mouse.outlineColor = parseColor(from: value, field: key)
      case "mouse_size":
        try self.mouse.size = parseCgFloat(value: value, field: key)
      case "mouse_color_normal":
        try self.mouse.colorNormal = parseColor(from: value, field: key)
      case "mouse_color_visual":
        try self.mouse.colorVisual = parseColor(from: value, field: key)
      case "hint_triangle_height":
        try self.hintTriangleHeight = parseCgFloat(value: value, field: key)
      case "hint_font_size":
        try self.hintFontSize = parseCgFloat(value: value, field: key)
      case "cursor_step":
        try self.cursorStep = parseInt(value: value, field: key)
      case "scroll_size_vertical":
        try self.scrollSize.vertical = parseInt(value: value, field: key)
      case "scroll_size_vertical_page":
        try self.scrollSize.verticalPage = parseInt(
          value: value, field: key)
      case "scroll_size_horizontal":
        try self.scrollSize.horizontal = parseInt(value: value, field: key)
      case "jiggle_when_dragging":
        try self.jiggleWhenDragging = parseBool(value: value, field: key)
      case "color_fg":
        try self.colors.fg = parseColor(from: value, field: key)
      case "color_bg":
        try self.colors.bg = parseColor(from: value, field: key)
      case "hint_chars":
        var charsSet = Set<String>()
        let chars = value.filter { char in char.uppercased() != char.lowercased() }
        let seperator = ""
        for char in chars.split(separator: seperator) {
          charsSet.insert(String(char))
        }
        guard charsSet.count >= 8 else {
          throw ParseError(message: "At least 8 chars must be used for hinting")
        }
        self.hintChars = charsSet.joined(separator: seperator)
      case "grid_rows":
        try self.grid.rows = parseInt(value: value, field: key)
      case "grid_cols":
        try self.grid.cols = parseInt(value: value, field: key)
      case "grid_font_size":
        try self.grid.fontSize = parseCgFloat(value: value, field: key)
      case "hint_selection":
        switch value {
        case "role":
          self.selection = SelectionType.role
        case "action":
          self.selection = SelectionType.action
        default:
          throw ParseError(message: "hint_selection must be either action or role")
        }
      case "debug_perf":
        try self.debugPerf = parseBool(value: value, field: key)
      case "hint_text":
        try self.hintText = parseBool(value: value, field: key)
      case "system_menu_poll":
        guard let val = Int(value), val == 0 || val >= 10
        else { throw ParseError(message: "system_menu_poll must be 0 or greater than 10") }
        self.systemMenuPoll = val
      case "traverse_hidden":
        try self.traverseHidden = parseBool(value: value, field: key)
      case "key_show_hints":
        try self.keyMappings.showHints = parseKeyMapping(
          from: value, field: key, flags: [.requireModifiers])
      case "key_show_grid":
        try self.keyMappings.showGrid = parseKeyMapping(
          from: value, field: key, flags: [.requireModifiers])
      case "key_start_scroll":
        try self.keyMappings.startScroll = parseKeyMapping(
          from: value, field: key, flags: [.requireModifiers])
      case "key_close":
        try self.keyMappings.close = parseKeyMapping(
          from: value, field: key, flags: [.notInHintChars])

      case "key_enter_search_mode":
        try self.keyMappings.enterSearchMode = parseKeyMapping(
          from: value, field: key, flags: [.notInHintChars])

      case "key_next_search_occurence":
        try self.keyMappings.nextSearchOccurence = parseKeyMapping(
          from: value, field: key, flags: [.nonPrintableChar])

      case "key_prev_search_occurence":
        try self.keyMappings.prevSearchOccurence = parseKeyMapping(
          from: value, field: key, flags: [.nonPrintableChar])

      case "key_select_occurence":
        try self.keyMappings.selectOccurence = parseKeyMapping(
          from: value, field: key, flags: [.nonPrintableChar])
      case "key_drop_last_search_char":
        try self.keyMappings.dropLastSearchChar = parseKeyMapping(
          from: value, field: key, flags: [.nonPrintableChar])
      case "key_toggle_z_index":
        try self.keyMappings.toggleZIndex = parseKeyMapping(
          from: value, field: key, flags: [.notInHintChars])
      case "key_mouse_left":
        try self.keyMappings.mouseLeft = parseKeyMapping(from: value, field: key)
      case "key_mouse_down":
        try self.keyMappings.mouseDown = parseKeyMapping(from: value, field: key)
      case "key_mouse_up":
        try self.keyMappings.mouseUp = parseKeyMapping(from: value, field: key)
      case "key_mouse_right":
        try self.keyMappings.mouseRight = parseKeyMapping(from: value, field: key)
      case "key_scroll_left":
        try self.keyMappings.scrollLeft = parseKeyMapping(
          from: value, field: key, flags: [.requireModifiers])
      case "key_scroll_down":
        try self.keyMappings.scrollDown = parseKeyMapping(
          from: value, field: key, flags: [.requireModifiers])
      case "key_scroll_up":
        try self.keyMappings.scrollUp = parseKeyMapping(
          from: value, field: key, flags: [.requireModifiers])
      case "key_scroll_right":
        try self.keyMappings.scrollRight = parseKeyMapping(
          from: value, field: key, flags: [.requireModifiers])
      case "key_scroll_page_down":
        try self.keyMappings.scrollPageDown = parseKeyMapping(from: value, field: key)
      case "key_scroll_page_up":
        try self.keyMappings.scrollPageUp = parseKeyMapping(from: value, field: key)
      case "key_scroll_full_down":
        try self.keyMappings.scrollFullDown = parseKeyMapping(from: value, field: key)
      case "key_scroll_full_up":
        try self.keyMappings.scrollFullUp = parseKeyMapping(from: value, field: key)
      case "key_enter_visual":
        try self.keyMappings.enterVisual = parseKeyMapping(from: value, field: key)
      case "key_reopen_grid_view":
        try self.keyMappings.reopenGridView = parseKeyMapping(from: value, field: key)
      case "key_right_click":
        try self.keyMappings.rightClick = parseKeyMapping(from: value, field: key)
      case "key_left_click":
        try self.keyMappings.leftClick = parseKeyMapping(from: value, field: key)
      default: continue
      }
    }
  }

  private func parseColor(from hex: String, field: String) throws -> Color {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized

    guard hexSanitized.count == 6 || hexSanitized.count == 8 else {
      throw ParseError(message: "\(field) must be a hex string, e.g. #000000")
    }

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

  private func readConfigFile(path: String) {
    let fs = FileManager.default
    if !fs.fileExists(atPath: path) {
      print("Config file not found at '\(path)', using defaults")
      return
    }

    do {
      let contents = try String(contentsOfFile: path, encoding: .utf8)
      try proccessOptions(contents)
      print("Config parsed successfully")
    } catch let err as ParseError {
      print("Parse error in config file: \(err.message)")
      exit(1)
    } catch {
      print("Error reading config file: \(error)")
      exit(1)
    }
  }

  private init() {
    if let configPath = ProcessInfo.processInfo.environment["VIMIUM_CONFIG_PATH"] {
      print("VIMIUM_CONFIG_PATH is set reading from custom path '\(configPath)'")
      readConfigFile(path: configPath)
    } else {
      let filename = "vimium"
      let fileManager = FileManager.default
      let homeDirectoryURL = fileManager.homeDirectoryForCurrentUser
      let configDirectoryURL = homeDirectoryURL.appendingPathComponent(".config", isDirectory: true)
      let filePath = configDirectoryURL.appendingPathComponent(filename).path
      readConfigFile(path: filePath)
    }
  }
}
