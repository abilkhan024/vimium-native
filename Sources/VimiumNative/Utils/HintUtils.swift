@MainActor
class HintUtils {
  static private var labelSeq: [String] = []

  static func genLabels(from n: Int) -> [String] {
    var result: [String] = labelSeq
    let chars = AppOptions.get().hintChars.split(separator: "").map { sub in String(sub) }
    var q: [String] = chars

    if q.isEmpty {
      return result
    }

    while result.count < n {
      let cur = q.first!
      result.append(cur)
      for char in chars {
        let next = cur + char
        q.append(next)
      }
      q = Array(q.dropFirst())
    }
    labelSeq = result

    return result
  }
}
