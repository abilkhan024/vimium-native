@MainActor
class HintUtils {
  static private var labelSequence: [[String]] = [
    AppOptions.get()
      .hintChars.split(separator: "")
      .map { sub in String(sub) }
  ]

  static func getLabels(from n: Int) -> [String] {
    var idx = 0
    while n > labelSequence[idx].count {
      if idx + 1 >= labelSequence.count {
        var seq: [String] = []
        for sub in labelSequence[idx] {
          for char in labelSequence[0] {
            seq.append(sub + char)
          }
        }
        labelSequence.append(seq)
      }
      idx = idx + 1
    }

    return labelSequence[idx]
  }
}
