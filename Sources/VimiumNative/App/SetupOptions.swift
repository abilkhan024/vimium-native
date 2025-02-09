// Read .config later
@MainActor
class AppOptions {
  let hintChars = "asdfghjklweruio"

  private static var loaded: AppOptions?

  static func load() -> AppOptions {
    guard let singletone = loaded else {
      let instance = AppOptions()
      loaded = instance
      return instance

    }
    return singletone
  }

}
