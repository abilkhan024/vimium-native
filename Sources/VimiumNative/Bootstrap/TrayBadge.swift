import Cocoa

@MainActor
class TrayBadge {
  var statusItem: NSStatusItem?
  var onOpen: Selector
  var onQuit: Selector

  init(onOpen: Selector, onQuit: Selector) {
    self.onOpen = onOpen
    self.onQuit = onQuit
    setupTrayIcon()
  }

  private func setupTrayIcon() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    guard let statusButton = statusItem?.button else { return }

    // Configure the status button's image
    statusButton.image = NSImage(
      systemSymbolName: "circle.fill", accessibilityDescription: "App Running")
    statusButton.image?.isTemplate = true

    // Add the badge to the button
    setupTrayBadge(for: statusButton)

    // Configure the menu
    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: "Open App", action: onOpen, keyEquivalent: "O"))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Quit", action: onQuit, keyEquivalent: "Q"))
    statusItem?.menu = menu
  }

  private func setupTrayBadge(for statusButton: NSStatusBarButton) {
    let badgeView = NSTextField(labelWithString: "•")
    badgeView.textColor = .red
    badgeView.font = NSFont.systemFont(ofSize: 10)
    badgeView.isBordered = false
    badgeView.backgroundColor = .clear
    badgeView.sizeToFit()

    statusButton.addSubview(badgeView)
    badgeView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      badgeView.trailingAnchor.constraint(equalTo: statusButton.trailingAnchor, constant: -4),
      badgeView.bottomAnchor.constraint(equalTo: statusButton.bottomAnchor, constant: -4),
    ])
  }
}
