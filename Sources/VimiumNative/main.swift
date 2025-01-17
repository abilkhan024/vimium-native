import ApplicationServices
import Cocoa
import CoreGraphics
import Foundation
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
  var badge: TrayBadge?
  let window = Window()
  let system = System()

  func applicationDidFinishLaunching(_ notification: Notification) {
    system.pipeOutput()
    system.attachMenu(quit: #selector(quitApp))
    badge = TrayBadge(onOpen: #selector(openApp), onQuit: #selector(quitApp))
  }

  @objc private func openApp() {
    window.open(view: SettingsView())
  }

  @objc private func quitApp() {
    system.die()
  }
}

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
