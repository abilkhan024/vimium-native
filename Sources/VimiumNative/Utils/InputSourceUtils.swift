import Carbon

@MainActor
class InputSourceUtils {
  private static var current: TISInputSource? = nil

  private static func getCurrentInputSource() -> TISInputSource {
    TISCopyCurrentKeyboardInputSource().takeRetainedValue()
  }

  private static func getInputSourceId(src: TISInputSource) -> String {
    guard let prop = TISGetInputSourceProperty(src, kTISPropertyInputSourceID) else { return "" }
    return unsafeBitCast(prop, to: CFString.self) as String
  }

  private static func getAllInputSources() -> [TISInputSource] {
    TISCreateInputSourceList(
      [kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource] as CFDictionary,
      false
    ).takeRetainedValue() as! [TISInputSource]
  }

  private static func findLatinInputSource() -> TISInputSource? {
    for src in getAllInputSources() {
      let id = getInputSourceId(src: src)
      let isLatin = id == "com.apple.keylayout.ABC"
      if isLatin {
        return src
      }
    }
    return nil
  }

  static func restoreCurrent() {
    guard let cur = current else { return }
    TISSelectInputSource(cur)
    current = nil
  }

  static func selectLatin() {
    current = getCurrentInputSource()
    guard let latin = findLatinInputSource() else { return }
    TISSelectInputSource(latin)
  }
}
