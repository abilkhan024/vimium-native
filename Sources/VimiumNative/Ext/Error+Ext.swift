import Foundation

private extension Int {
  static let defaultCode = 0
}

private extension String {
  static let defaultDomain = "defaultError"
}

extension NSError {
  var defaultError: NSError {
    NSError(domain: .defaultDomain, code: .defaultCode)
  }

  convenience init(localizedDescription: String) {
    self.init(
      domain: .defaultDomain,
      code: .defaultCode,
      userInfo: [NSLocalizedDescriptionKey: localizedDescription],
    )
  }
}
