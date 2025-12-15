@preconcurrency import ApplicationServices

protocol IAccessibilityChecker {
  var trusted: Bool { get }
}

final class AccessibilityChecker: IAccessibilityChecker {
  var trusted: Bool {
    AXIsProcessTrustedWithOptions([
      kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true,
    ] as CFDictionary)
  }
}
