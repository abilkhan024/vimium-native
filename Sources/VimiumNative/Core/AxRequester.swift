import ApplicationServices
import Darwin

@MainActor
final class AxRequester {
  static let shared = AxRequester()

  private var lastExec = -1
  private var requestCounter = 0
  private let cooldownMs: useconds_t = 1_000
  private let tickMs: useconds_t = 1_000

  private init() {}

  func waitCooldown() {
    let now = Int(floor(Double(mach_absolute_time()) / 1000.0))
    if now - lastExec > tickMs {
      requestCounter = 0
      lastExec = now
    }
    requestCounter += 1
    print(requestCounter)
    let count = requestCounter.remainderReportingOverflow(dividingBy: 300)
    if count.partialValue == 0 {
      usleep(cooldownMs)
      print("You're on a cooldown")
    }
  }

  func copyAttribute(
    _ element: AXUIElement, _ attribute: String, _ value: UnsafeMutablePointer<CFTypeRef?>
  ) -> AXError {
    // waitCooldown()
    return AXUIElementCopyAttributeValue(element, attribute as CFString, value)
  }
}
