import ApplicationServices
import Foundation

// DEVELOPMENT ONLY: Records every node visited by AxElement.findVisible with
// the reason it didn't end up as a hint, to debug missing hints. Only active
// when `debug=true` in the config. The full tree (including subtrees the
// traversal pruned) is written to /tmp/vimium-traversal-<timestamp>.log,
// summary is printed to stdout prefixed with [traversal]
@MainActor
final class TraversalRecorder {
  struct Entry {
    let element: AxElement
    // nil when hinted
    var reason: AxSkipReason?
    let depth: Int
  }

  // Reasons that skip the children, which are then walked separately when
  // writing the log. Cycle is left out since its subtree was already visited
  private static let pruningReasons: Set<AxSkipReason> = [.noBound, .emptyBound, .offscreen]
  // Safety net for walking pruned subtrees, they can be huge (e.g. long pages)
  private static let prunedLimit = 20_000

  private static let attributes: [(key: String, attribute: String)] = [
    ("subrole", kAXSubroleAttribute),
    ("roledesc", kAXRoleDescriptionAttribute),
    ("title", kAXTitleAttribute),
    ("desc", kAXDescriptionAttribute),
    ("value", kAXValueAttribute),
    ("label", kAXLabelValueAttribute),
    ("help", kAXHelpAttribute),
    ("id", kAXIdentifierAttribute),
    ("dom.id", "AXDOMIdentifier"),
    ("dom.class", "AXDOMClassList"),
    ("enabled", kAXEnabledAttribute),
    ("focused", kAXFocusedAttribute),
  ]

  private static var app = ""
  private(set) static var entries: [Entry] = []

  static var enabled: Bool { AppOptions.shared.debug }

  static func begin(app: String) {
    guard enabled else { return }
    self.app = app
    entries = []
  }

  // `reason` is only evaluated when recording, so it costs nothing otherwise
  static func record(_ el: AxElement, _ reason: @autoclosure () -> AxSkipReason?) {
    guard enabled else { return }
    entries.append(Entry(element: el, reason: reason(), depth: el.parents.count))
  }

  // `hints` are the ones actually shown, hinted entries missing from it were
  // dropped as duplicates
  static func flush(hints: [AxElement]) {
    guard enabled, !entries.isEmpty else { return }
    let start = BenchUtils.now()

    // Same key as the dedupe in FzFindListener
    var pointOwners: [Int: AxElement] = [:]
    for hint in hints {
      if let point = hint.point { pointOwners[point.hashValue] = hint }
    }
    let shown = Set(hints.map { ObjectIdentifier($0) })
    for i in entries.indices
    where entries[i].reason == nil && !shown.contains(ObjectIdentifier(entries[i].element)) {
      entries[i].reason = .duplicatePoint
    }

    let window = entries.first?.element.bound
    var counts: [String: Int] = [:]
    var pruned = (left: prunedLimit, hintable: 0)
    var body: [String] = []
    for entry in entries {
      let el = entry.element
      counts[entry.reason?.rawValue ?? "hinted", default: 0] += 1
      body.append(
        line(
          el, result: entry.reason?.rawValue ?? "hinted",
          why: explain(el, entry.reason, window: window, pointOwners: pointOwners)))
      if let reason = entry.reason, pruningReasons.contains(reason) {
        appendPruned(el, window: window, pruned: &pruned, to: &body)
      }
    }

    let summary = counts.sorted { a, b in a.value > b.value }.map { "\($0.key): \($0.value)" }
    let prunedCount = prunedLimit - pruned.left
    let prunedSummary =
      "\(prunedCount) nodes inside pruned subtrees, \(pruned.hintable) of them hintable on their own"
      + (pruned.left <= 0 ? " (stopped at the limit of \(prunedLimit))" : "")
    let header = [
      "app: \(app)",
      "window: \(format(window))",
      "hint_text: \(AppOptions.shared.hintText), "
        + "small_node_threshold: \(AppOptions.shared.smallNodeThreshold), "
        + "ignore_empty_depth: \(AppOptions.shared.ignoreEmptyDepth)",
      "visited: \(entries.count), \(summary.joined(separator: ", "))",
      prunedSummary,
      "written in \(BenchUtils.ms(BenchUtils.now() - start))",
      "",
      "Format: [result] role (x,y wxh) children=N attributes... actions=[...] -- why",
      "  [hinted] or [<reason>]: node visited by the traversal",
      "  [pruned: <result>]: node the traversal never reached because an ancestor's subtree was",
      "    pruned, result is what the traversal would decide if it got there",
      "  '!' prefix: never reached, but hintable on its own (would most likely be a hint)",
      "",
    ]

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    let path = "/tmp/vimium-traversal-\(formatter.string(from: Date())).log"
    do {
      try (header + body).joined(separator: "\n").write(
        toFile: path, atomically: true, encoding: .utf8)
      print("[traversal] \(app): \(summary.joined(separator: ", "))")
      print("[traversal] \(prunedSummary)")
      print("[traversal] written to \(path)")
    } catch {
      print("[traversal] failed to write \(path): \(error)")
    }
    entries = []
  }

  // Walks the subtree the same way findVisible would, but without pruning
  private static func appendPruned(
    _ parent: AxElement, window: CGRect?, pruned: inout (left: Int, hintable: Int),
    to lines: inout [String]
  ) {
    for child in parent.getChildren() {
      guard pruned.left > 0 else { return }
      pruned.left -= 1
      let el = AxElement(child, parents: parent.parents + [parent])
      let reason = el.getSkipReason()
      let hintable = el.getUnhintableReason() == nil
      if hintable { pruned.hintable += 1 }
      lines.append(
        line(
          el, result: "pruned: \(reason?.rawValue ?? "hinted")",
          why: explain(el, reason, window: window, pointOwners: [:]), marked: hintable))
      if reason != .cycle {
        appendPruned(el, window: window, pruned: &pruned, to: &lines)
      }
    }
  }

  private static func line(
    _ el: AxElement, result: String, why: String, marked: Bool = false
  ) -> String {
    let role = el.role?.rawValue ?? el.raw.axRole() ?? "nil"
    var parts = [
      "\(marked ? "! " : "")[\(result)] \(role) \(format(el.bound))",
      "children=\(el.getChildren().count)",
    ]
    let values = el.raw.axDebugAttributes(attributes.map { $0.attribute })
    for (i, value) in values.enumerated() {
      guard let value, !value.isEmpty else { continue }
      let key = attributes[i].key
      // Only the unusual values are interesting
      if (key == "enabled" && value == "true") || (key == "focused" && value == "false") {
        continue
      }
      parts.append("\(key)=\(quote(value))")
    }
    let actions = el.raw.axActionNames()
    if !actions.isEmpty {
      parts.append("actions=[\(actions.joined(separator: ", "))]")
    }
    return indent(el.parents.count) + parts.joined(separator: " ") + " -- \(why)"
  }

  private static func explain(
    _ el: AxElement, _ reason: AxSkipReason?, window: CGRect?, pointOwners: [Int: AxElement]
  ) -> String {
    switch reason {
    case nil:
      return "hint at \(format(el.point))"
    case .cycle:
      return "same element as one of its ancestors"
    case .noBound:
      return "position or size is missing, subtree skipped"
    case .emptyBound:
      return "bound has no area, \(el.emptyDepth) in a row > ignore_empty_depth, subtree skipped"
    case .offscreen:
      return "bound doesn't intersect window \(format(window)), subtree skipped"
    case .unknownRole:
      return "role isn't listed in AxRole"
    case .tooSmall:
      return "width or height <= 1"
    case .unhintableRole:
      return "role is in UNHINTABLE_ROLES"
    case .textInsideHintable:
      let ancestor = el.parents.last { parent in parent.getIsHintable() }
      return "inside hintable \(ancestor.map { short($0) } ?? "ancestor")"
    case .textWithoutContent:
      return "hint_text is on, but title/value/description/label have no letters or digits"
    case .emptyTraversed:
      return "bound has no area, but children are traversed, \(el.emptyDepth) in a row"
        + " <= ignore_empty_depth"
    case .outsideWindow:
      return "bound doesn't intersect window \(format(window)) minus the status bar"
    case .duplicatePoint:
      let owner = el.point.flatMap { point in pointOwners[point.hashValue] }
      return "hint at \(format(el.point)) is taken by \(owner.map { short($0) } ?? "another hint")"
    }
  }

  private static func short(_ el: AxElement) -> String {
    let role = el.role?.rawValue ?? el.raw.axRole() ?? "nil"
    let text = AxElement.ownText(el.raw).map { " \(quote($0))" } ?? ""
    return "\(role)\(text) \(format(el.bound))"
  }

  private static func quote(_ text: String) -> String {
    let line = text.components(separatedBy: .newlines).joined(separator: " ")
    return "\"" + (line.count > 80 ? String(line.prefix(80)) + "…" : line) + "\""
  }

  private static func format(_ rect: CGRect?) -> String {
    guard let rect else { return "(no bound)" }
    return "(\(Int(rect.minX)),\(Int(rect.minY)) \(Int(rect.width))x\(Int(rect.height)))"
  }

  private static func format(_ point: CGPoint?) -> String {
    guard let point else { return "(no point)" }
    return "(\(Int(point.x)),\(Int(point.y)))"
  }

  private static func indent(_ depth: Int) -> String {
    return String(repeating: "  ", count: depth)
  }
}
