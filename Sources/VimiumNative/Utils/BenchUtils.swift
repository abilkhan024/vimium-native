import CoreFoundation
import Foundation

// DEVELOPMENT ONLY: Timing helpers to find where the hints latency goes.
// Output is printed to stdout prefixed with [bench], and only when `debug` is
// on. All callers run on the main thread
final class BenchUtils {
  // DEVELOPMENT ONLY: Flip locally to print bench output, never ship as true
  static let debug = false

  nonisolated(unsafe) private static var totals: [String: (ns: UInt64, count: Int)] = [:]
  nonisolated(unsafe) private static var counters: [String: Int] = [:]
  // Time the last matched key event reached the event tap callback
  nonisolated(unsafe) static var tapTime: UInt64 = 0

  static func now() -> UInt64 {
    return clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
  }

  static func ms(_ ns: UInt64) -> String {
    return String(format: "%.2fms", Double(ns) / 1_000_000)
  }

  // Accumulates time of `block` under `key`, see `printTotals`
  @discardableResult
  static func measure<T>(_ key: String, _ block: () throws -> T) rethrows -> T {
    let start = now()
    defer { add(key, now() - start) }
    return try block()
  }

  static func add(_ key: String, _ ns: UInt64) {
    let prev = totals[key] ?? (ns: 0, count: 0)
    totals[key] = (ns: prev.ns + ns, count: prev.count + 1)
  }

  static func count(_ key: String, by n: Int = 1) {
    counters[key, default: 0] += n
  }

  static func resetTotals() {
    totals = [:]
    counters = [:]
  }

  static func printTotals(_ title: String) {
    guard debug else { return }
    print("[bench] \(title) totals:")
    for (key, val) in totals.sorted(by: { a, b in a.value.ns > b.value.ns }) {
      let avg = val.count > 0 ? val.ns / UInt64(val.count) : 0
      print("[bench]   \(key): \(ms(val.ns)) over \(val.count) calls (avg \(ms(avg)))")
    }
    for (key, val) in counters.sorted(by: { a, b in a.key < b.key }) {
      print("[bench]   \(key): \(val)")
    }
  }

  // Calls `block` once after the current main run loop iteration has run its
  // CoreAnimation commit (SwiftUI body + layout + layer commit happen there)
  static func afterNextCommit(_ block: @escaping () -> Void) {
    // Only used to print output, so don't hook into the run loop at all
    guard debug else { return }
    let observer = CFRunLoopObserverCreateWithHandler(
      nil, CFRunLoopActivity.beforeWaiting.rawValue, false, CFIndex.max
    ) { _, _ in block() }
    CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .commonModes)
  }
}

// Sequential timeline, every `mark` prints time since the previous mark and
// since the start
final class BenchTimeline {
  private let name: String
  private let start: UInt64
  private var last: UInt64

  init(_ name: String, start: UInt64 = BenchUtils.now()) {
    self.name = name
    self.start = start
    self.last = start
  }

  func mark(_ label: String) {
    guard BenchUtils.debug else { return }
    let cur = BenchUtils.now()
    print(
      "[bench] \(name) | \(label): +\(BenchUtils.ms(cur - last)) (total \(BenchUtils.ms(cur - start)))"
    )
    last = cur
  }
}
