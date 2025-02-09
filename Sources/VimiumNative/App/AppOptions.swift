
// TODO: Read .config later
@MainActor
class AppOptions {
  let hintChars = "asdfghjklweruiozxcvbnmqp"

  private static var shared: AppOptions?

  static func get() -> AppOptions {
    guard let singletone = shared else {
      let instance = AppOptions()
      shared = instance
      return instance

    }
    return singletone
  }

}
