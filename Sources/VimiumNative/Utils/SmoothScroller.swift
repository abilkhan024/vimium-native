import Foundation
import QuartzCore

// NOTE: Distributes scroll delta across frames at constant speed. Deltas added
// mid-animation (e.g. key repeat) are merged into the remaining distance and
// push the deadline, so holding a scroll key produces continuous motion
// instead of restarting the animation on every repeat
@MainActor
final class SmoothScroller {
  static let shared = SmoothScroller()

  private let frameInterval = 1.0 / 120.0
  private var timer: DispatchSourceTimer?
  private var lastTick: CFTimeInterval = 0
  // Moment by which remaining distance must be scrolled
  private var deadline: CFTimeInterval = 0
  // Distance that is yet to be scrolled
  private var remaining = (x: 0.0, y: 0.0)
  // Sub-pixel leftovers, scroll events only accept integers
  private var carry = (x: 0.0, y: 0.0)

  private init() {}

  func scroll(deltaY: Int, deltaX: Int = 0) {
    guard AppOptions.shared.smoothScrollDuration > 0 else {
      return EventUtils.scroll(deltaY: Int32(deltaY), deltaX: Int32(deltaX))
    }
    remaining.x += Double(deltaX)
    remaining.y += Double(deltaY)
    deadline = CACurrentMediaTime() + Double(AppOptions.shared.smoothScrollDuration) / 1000
    if timer == nil {
      start()
    }
  }

  func stop() {
    timer?.cancel()
    timer = nil
    remaining = (0, 0)
    carry = (0, 0)
  }

  private func start() {
    lastTick = CACurrentMediaTime()
    let timer = DispatchSource.makeTimerSource(queue: .main)
    timer.schedule(deadline: .now(), repeating: frameInterval, leeway: .milliseconds(1))
    timer.setEventHandler {
      MainActor.assumeIsolated { self.tick() }
    }
    self.timer = timer
    timer.resume()
  }

  private func tick() {
    let now = CACurrentMediaTime()
    // Share of the remaining distance that falls into elapsed time, flushes
    // everything once deadline is reached
    let timeLeft = deadline - lastTick
    let progress = timeLeft > 0 ? min(1, (now - lastTick) / timeLeft) : 1
    lastTick = now

    let x = step(remaining.x, progress, &carry.x)
    let y = step(remaining.y, progress, &carry.y)
    remaining.x -= Double(x)
    remaining.y -= Double(y)

    if x != 0 || y != 0 {
      EventUtils.scroll(deltaY: Int32(y), deltaX: Int32(x), continuous: true)
    }
    // Deltas and steps are whole pixels, so remaining reaches exactly zero
    if remaining.x == 0 && remaining.y == 0 {
      stop()
    }
  }

  private func step(_ remaining: Double, _ progress: Double, _ carry: inout Double) -> Int {
    if remaining == 0 { return 0 }
    let exact = remaining * progress + carry
    var whole = exact.rounded(.towardZero)
    carry = exact - whole
    // Never overshoot the target
    if abs(whole) > abs(remaining) {
      whole = remaining
    }
    return Int(whole)
  }
}
