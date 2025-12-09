import Carbon

@MainActor
class InputSourceUtils {
  private static var current: TISInputSource? = nil

  private static func getCurrentInputSource() -> TISInputSource {
    TISCopyCurrentKeyboardInputSource().takeRetainedValue()
  }

  static func getInputSourceId(src: TISInputSource) -> String {
    guard let prop = TISGetInputSourceProperty(src, kTISPropertyInputSourceID) else { return "" }
    return unsafeBitCast(prop, to: CFString.self) as String
  }

  static func getAllInputSources() -> [TISInputSource] {
    TISCreateInputSourceList(
      [kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource] as CFDictionary,
      false
    ).takeRetainedValue() as! [TISInputSource]
  }

  private static func findAbcInputSource() -> TISInputSource? {
    for src in getAllInputSources() {
      if getInputSourceId(src: src) == AppOptions.shared.abcLayout {
        return src
      }
    }
    return nil
  }

  static func restoreCurrent() {
    guard let cur = current else { return }
    let realCurrent = getCurrentInputSource()
    if realCurrent != cur {
      TISSelectInputSource(cur)
      current = nil
    }
  }

  static func selectAbc() {
    let realCurrent = getCurrentInputSource()
    guard let target = findAbcInputSource() else { return }
    if realCurrent != target {
      TISSelectInputSource(target)
      current = realCurrent
    }
  }
}
