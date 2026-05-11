import Foundation
import Combine

@Observable
final class AppState {
    let permissionsManager = PermissionsManager()
    let settingsManager = SettingsManager()
    let menuBarController = MenuBarController()
    let menuBarMonitor = MenuBarMonitor()
    let hotkeyManager = HotkeyManager()
    let mouseTracker = MouseTracker()
    let presetManager = PresetManager()
    let triggerManager = TriggerManager()
    let showForUpdatesTracker = ShowForUpdatesTracker()

    let fringerBarPanel = FringerBarPanel()
    let searchPanel = SearchPanel()

    private var notificationObserver: Any?
    private var permissionObservation: Any?

    var isSetupComplete: Bool {
        permissionsManager.allPermissionsGranted
    }

    init() {
        start()
    }

    func start() {
        menuBarController.setup()

        menuBarMonitor.startMonitoring()

        notificationObserver = NotificationCenter.default.addObserver(
            forName: .toggleFringerBar,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.toggleFringerBar()
        }

        setupPermissionObservation()
        setupHotkeys()
        setupHoverTracking()
        setupTriggers()
        setupShowForUpdates()
    }

    private func setupPermissionObservation() {
        permissionObservation = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            let wasAccessible = self.permissionsManager.accessibilityGranted
            self.permissionsManager.checkPermissions()
            if self.permissionsManager.accessibilityGranted, !wasAccessible {
                self.menuBarMonitor.refresh()
            }
            if self.permissionsManager.allPermissionsGranted {
                self.menuBarMonitor.refresh()
                timer.invalidate()
            }
        }
    }

    private func setupHotkeys() {
        hotkeyManager.onToggleFringerBar = { [weak self] in
            self?.toggleFringerBar()
        }
        hotkeyManager.onQuickSearch = { [weak self] in
            self?.showSearch()
        }
        hotkeyManager.registerHotkeys()
    }

    private func setupHoverTracking() {
        guard settingsManager.showOnHover else { return }

        mouseTracker.onMenuBarHover = { [weak self] in
            guard let self, settingsManager.showOnHover else { return }
            showFringerBar()
        }
        mouseTracker.onMenuBarExit = { [weak self] in
            guard let self else { return }
            mouseTracker.scheduleHide(after: settingsManager.hideDelay) { [weak self] in
                self?.hideFringerBar()
            }
        }
        mouseTracker.startTracking()
    }

    private func setupTriggers() {
        triggerManager.onActivatePreset = { [weak self] presetID in
            guard let self,
                  let preset = presetManager.presets.first(where: { $0.id == presetID }) else { return }
            presetManager.activatePreset(preset, settingsManager: settingsManager)
        }
        triggerManager.startMonitoring()
    }

    private func setupShowForUpdates() {
        menuBarMonitor.onItemsUpdated = { [weak self] items in
            guard let self else { return }
            let hiddenNames = Set(items.compactMap { item -> String? in
                self.settingsManager.getSection(for: item.ownerName) == .hidden ? item.ownerName : nil
            })
            showForUpdatesTracker.checkForUpdates(items: items, hiddenOwnerNames: hiddenNames)
        }
    }

    func toggleFringerBar() {
        if fringerBarPanel.isVisible {
            hideFringerBar()
        } else {
            showFringerBar()
        }
    }

    func showFringerBar() {
        let hiddenItems = menuBarMonitor.items.filter {
            settingsManager.getSection(for: $0.ownerName) == .hidden
        }
        let displayItems = hiddenItems.isEmpty ? menuBarMonitor.items : hiddenItems

        fringerBarPanel.updateContent(items: displayItems) { [weak self] item in
            self?.menuBarMonitor.clickItem(item)
            self?.hideFringerBar()
        }
        fringerBarPanel.showBelow(statusItem: menuBarController.mainStatusItem)
        menuBarController.isHiddenSectionVisible = true
    }

    func hideFringerBar() {
        fringerBarPanel.dismiss()
        menuBarController.isHiddenSectionVisible = false
    }

    func showSearch() {
        searchPanel.show(
            items: menuBarMonitor.items,
            onSelect: { [weak self] item in
                self?.menuBarMonitor.clickItem(item)
            },
            onDismiss: { }
        )
    }
}
