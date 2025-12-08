import Foundation

private extension String {
  static let daemonTemplateName = "DaemonTemplate"
  static let daemonTemplateExtension = "plist"

  static let daemonDomainTemplate = "gui/%d"
  static let daemonTargetTemplate = "\(daemonDomainTemplate)/%@"

  static let launchctlExecutable = "/bin/launchctl"

  static let launchctlStatusArgument = "print"

  static let launchctlAutoLaunchEnableArgument = "enable"
  static let launchctlAutoLaunchDisableArgument = "disable"

  static let launchctlEnableArgument = "bootstrap"
  static let launchctlDisableArgument = "bootout"

  static let launchctlStartArgument = "kickstart"
  static let launchctlStopArgument = "kill"
}

private extension Int32 {
  var isSuccessStatus: Bool { self == 0 }
}

@MainActor
protocol IDaemon {
  init(name: String, packageName: String)
  func start() throws
  func stop() throws
  func restart() throws
}

final class Daemon: IDaemon {

  private let name: String
  private let packageName: String

  required init(name: String, packageName: String) {
    self.name = name
    self.packageName = packageName
  }

  func start() throws {
    guard
      let contents = String(bytes: PackageResources.DaemonTemplate_plist, encoding: .utf8),
      let executablePath = Bundle.main.executablePath
    else { throw NSError(localizedDescription: "Internal error on daemon registration") }

    let rawPlist = String(format: contents, name, packageName, executablePath)
    try rawPlist.write(to: destination, atomically: true, encoding: .utf8)

    let userId = getuid()
    let target = String(format: .daemonTargetTemplate, userId, packageName)

    if try exec(.launchctlExecutable,
                argv: [String.launchctlStatusArgument, target]).isSuccessStatus {
      let status = try exec(.launchctlExecutable,
                            argv: [String.launchctlStartArgument, target])
      guard status.isSuccessStatus else {
        throw NSError(localizedDescription: "Failed \(String.launchctlStartArgument) with \(status)")
      }
    } else {
      _ = try exec(.launchctlExecutable,
                   argv: [String.launchctlAutoLaunchEnableArgument, target])
      let domain = String(format: .daemonDomainTemplate, userId)
      let status = try exec(.launchctlExecutable,
                            argv: [String.launchctlEnableArgument, domain, destination.path])
      guard status.isSuccessStatus else {
        throw NSError(localizedDescription: "Failed \(String.launchctlEnableArgument) with \(status)")
      }
    }
  }

  func stop() throws {
    let userId = getuid()
    let target = String(format: .daemonTargetTemplate, userId, packageName)

    if try exec(.launchctlExecutable,
                argv: [String.launchctlStatusArgument, target]).isSuccessStatus {
      let domain = String(format: .daemonDomainTemplate, userId)
      _ = try exec(.launchctlExecutable,
                   argv: [String.launchctlDisableArgument, domain, destination.path])
      let status = try exec(.launchctlExecutable,
                            argv: [String.launchctlAutoLaunchDisableArgument, target])
      guard status.isSuccessStatus else {
        throw NSError(localizedDescription: "Failed \(String.launchctlAutoLaunchDisableArgument) with \(status)")
      }
    } else {
      let status = try exec(.launchctlExecutable,
                            argv: [String.launchctlStopArgument, target])
      guard status.isSuccessStatus else {
        throw NSError(localizedDescription: "Failed \(String.launchctlStopArgument) with \(status)")
      }
    }
    try FileManager.default.removeItem(at: destination)
  }

  func restart() throws {
    let target = String(format: .daemonTargetTemplate, getuid(), packageName)
    let status = try exec(.launchctlExecutable,
                          argv: [String.launchctlStartArgument, "-k", target])
    guard status.isSuccessStatus else {
      throw NSError(localizedDescription: "Failed with \(status)")
    }
  }

  // MARK: Private

  private lazy var destination: URL = {
    var destination = URL.libraryDirectory
    destination.appendPathComponent("LaunchAgents")
    destination.appendPathComponent("\(packageName).plist")
    return destination
  }()

  private func exec(_ executable: String, argv: [String]? = nil) throws -> Int32 {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: executable)
    p.arguments = argv
    p.standardOutput = nil
    p.standardError = nil

    defer { p.terminate() }
    try p.run()
    p.waitUntilExit()
    return p.terminationStatus
  }
}
