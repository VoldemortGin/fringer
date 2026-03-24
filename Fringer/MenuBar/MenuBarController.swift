import AppKit

extension Notification.Name {
    static let toggleFringerBar = Notification.Name("toggleFringerBar")
}

@Observable
final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var hiddenSectionDivider: NSStatusItem?
    private var alwaysHiddenDivider: NSStatusItem?

    var isHiddenSectionVisible: Bool = false

    private let expandedLength: CGFloat = 10_000
    private let collapsedLength: CGFloat = 0

    var mainStatusItem: NSStatusItem? { statusItem }

    func setup() {
        setupStatusItem()
        setupDividers()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.autosaveName = "FringerMainItem"

        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "line.3.horizontal.decrease",
                accessibilityDescription: "Fringer"
            )
            button.image?.size = NSSize(width: 18, height: 18)
            button.image?.isTemplate = true
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func setupDividers() {
        hiddenSectionDivider = NSStatusBar.system.statusItem(withLength: collapsedLength)
        hiddenSectionDivider?.autosaveName = "FringerHiddenDivider"
        hiddenSectionDivider?.button?.image = nil

        alwaysHiddenDivider = NSStatusBar.system.statusItem(withLength: collapsedLength)
        alwaysHiddenDivider?.autosaveName = "FringerAlwaysHiddenDivider"
        alwaysHiddenDivider?.button?.image = nil
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            openSettings()
        } else {
            NotificationCenter.default.post(name: .toggleFringerBar, object: nil)
        }
    }

    func toggleHiddenSection() {
        isHiddenSectionVisible.toggle()

        if isHiddenSectionVisible {
            showHiddenSection()
        } else {
            hideHiddenSection()
        }
    }

    private func showHiddenSection() {
        hiddenSectionDivider?.length = expandedLength
    }

    private func hideHiddenSection() {
        hiddenSectionDivider?.length = collapsedLength
    }

    private func openSettings() {
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    deinit {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        if let item = hiddenSectionDivider {
            NSStatusBar.system.removeStatusItem(item)
        }
        if let item = alwaysHiddenDivider {
            NSStatusBar.system.removeStatusItem(item)
        }
    }
}
