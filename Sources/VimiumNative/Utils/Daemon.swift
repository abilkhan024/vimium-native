import Foundation

private extension String {
  static let daemonDomainTemplate = "gui/%d"
  static let daemonTargetTemplate = "\(daemonDomainTemplate)/%@"

  static let daemonStdoutTemplate = "%@-out.log"
  static let daemonStderrTemplate = "%@-err.log"

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

private extension Int16 {
  static let allReadWrite: Int16 = 0o666
}

@MainActor
protocol IDaemon {
  init(name: String, packageName: String)
  func start() throws
  func stop() throws
  func restart() throws
}

final class Daemon: IDaemon {

  // MARK: Properties

  private let name: String
  private let packageName: String
  private let fm = FileManager.default

  // MARK: Init

  required init(name: String, packageName: String) {
    self.name = name
    self.packageName = packageName
  }

  // MARK: IDaemon

  func start() throws {
    guard
      let contents = String(bytes: PackageResources.DaemonTemplate_plist, encoding: .utf8),
      let executablePath = Bundle.main.executablePath
    else { throw NSError(localizedDescription: "Internal error on daemon registration") }

    let tmp = URL(fileURLWithPath: "/tmp", isDirectory: true)
    let stdout = tmp.appendingPathComponent(String(format: .daemonStdoutTemplate, name))
    let stderr = tmp.appendingPathComponent(String(format: .daemonStderrTemplate, name))

    try prepareSharedUrl(stdout)
    try prepareSharedUrl(stderr)

    let rawPlist = String(format: contents, packageName, executablePath, stdout.path, stderr.path)
    try rawPlist.write(to: destination, atomically: true, encoding: .utf8)

    let userId = getuid()
    let target = String(format: .daemonTargetTemplate, userId, packageName)

    if try exec(
      .launchctlExecutable,
      argv: [String.launchctlStatusArgument, target]
    ).isSuccessStatus {
      let status = try exec(
        .launchctlExecutable,
        argv: [String.launchctlStartArgument, target],
      )
      guard status.isSuccessStatus else {
        throw NSError(
          localizedDescription: "Failed \(String.launchctlStartArgument) with code \(status)")
      }
    } else {
      _ = try exec(
        .launchctlExecutable,
        argv: [String.launchctlAutoLaunchEnableArgument, target],
      )
      let domain = String(format: .daemonDomainTemplate, userId)
      let status = try exec(
        .launchctlExecutable,
        argv: [String.launchctlEnableArgument, domain, destination.path],
      )
      guard status.isSuccessStatus else {
        throw NSError(
          localizedDescription: "Failed \(String.launchctlEnableArgument) with code \(status)")
      }
    }
  }

  func stop() throws {
    let userId = getuid()
    let target = String(format: .daemonTargetTemplate, userId, packageName)

    if try exec(
      .launchctlExecutable,
      argv: [String.launchctlStatusArgument, target]
    ).isSuccessStatus {
      let domain = String(format: .daemonDomainTemplate, userId)
      _ = try exec(
        .launchctlExecutable,
        argv: [String.launchctlDisableArgument, domain, destination.path],
      )
      let status = try exec(
        .launchctlExecutable,
        argv: [String.launchctlAutoLaunchDisableArgument, target],
      )
      guard status.isSuccessStatus else {
        throw NSError(
          localizedDescription: "Failed \(String.launchctlAutoLaunchDisableArgument) with code \(status)"
        )
      }
    } else {
      let status = try exec(
        .launchctlExecutable,
        argv: [String.launchctlStopArgument, target],
      )
      guard status.isSuccessStatus else {
        throw NSError(localizedDescription: "Failed \(String.launchctlStopArgument) with code \(status)")
      }
    }
    try fm.removeItem(at: destination)
  }

  func restart() throws {
    let target = String(format: .daemonTargetTemplate, getuid(), packageName)
    let status = try exec(
      .launchctlExecutable,
      argv: [String.launchctlStartArgument, "-k", target])
    guard status.isSuccessStatus else {
      throw NSError(localizedDescription: "Failed with code \(status)")
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

  private func prepareSharedUrl(_ url: URL) throws {
    try fm.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true,
    )

    fm.createFile(
      atPath: url.path,
      contents: nil,
      attributes: [.posixPermissions: Int16.allReadWrite],
    )
  }
}
