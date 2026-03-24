import AppKit
import IOKit.ps
import CoreWLAN
import Combine

@Observable
final class TriggerManager {
    private(set) var triggers: [Trigger] = []
    private var batteryTimer: Timer?
    private var wifiTimer: Timer?
    private var timeTimer: Timer?
    private var appObservers: [NSObjectProtocol] = []

    private let triggersKey = "savedTriggers"

    var onActivatePreset: ((UUID) -> Void)?

    init() {
        loadTriggers()
    }

    // MARK: - CRUD

    func addTrigger(_ trigger: Trigger) {
        triggers.append(trigger)
        saveTriggers()
        restartMonitoring()
    }

    func updateTrigger(_ trigger: Trigger) {
        guard let index = triggers.firstIndex(where: { $0.id == trigger.id }) else { return }
        triggers[index] = trigger
        saveTriggers()
        restartMonitoring()
    }

    func deleteTrigger(_ trigger: Trigger) {
        triggers.removeAll(where: { $0.id == trigger.id })
        saveTriggers()
        restartMonitoring()
    }

    func toggleTrigger(_ trigger: Trigger) {
        guard let index = triggers.firstIndex(where: { $0.id == trigger.id }) else { return }
        triggers[index].isEnabled.toggle()
        saveTriggers()
        restartMonitoring()
    }

    // MARK: - Monitoring

    func startMonitoring() {
        stopMonitoring()

        let enabledTriggers = triggers.filter(\.isEnabled)

        if enabledTriggers.contains(where: { $0.type == .battery }) {
            startBatteryMonitoring()
        }
        if enabledTriggers.contains(where: { $0.type == .wifi }) {
            startWiFiMonitoring()
        }
        if enabledTriggers.contains(where: { $0.type == .time }) {
            startTimeMonitoring()
        }
        if enabledTriggers.contains(where: { $0.type == .appLaunch }) {
            startAppMonitoring()
        }
    }

    func stopMonitoring() {
        batteryTimer?.invalidate()
        batteryTimer = nil
        wifiTimer?.invalidate()
        wifiTimer = nil
        timeTimer?.invalidate()
        timeTimer = nil
        appObservers.forEach { NotificationCenter.default.removeObserver($0) }
        appObservers.removeAll()
    }

    private func restartMonitoring() {
        startMonitoring()
    }

    // MARK: - Battery Monitoring

    private func startBatteryMonitoring() {
        checkBattery()
        batteryTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkBattery()
        }
    }

    private func checkBattery() {
        let batteryTriggers = triggers.filter { $0.type == .battery && $0.isEnabled }
        guard !batteryTriggers.isEmpty else { return }

        let (isCharging, percentage) = getBatteryStatus()

        for trigger in batteryTriggers {
            var shouldActivate = false

            switch trigger.batteryCondition {
            case .onBattery:
                shouldActivate = !isCharging
            case .charging:
                shouldActivate = isCharging
            case .belowPercent:
                if let threshold = trigger.batteryThreshold {
                    shouldActivate = percentage < threshold
                }
            case .none:
                break
            }

            if shouldActivate, let presetID = trigger.presetID {
                onActivatePreset?(presetID)
            }
        }
    }

    private func getBatteryStatus() -> (isCharging: Bool, percentage: Int) {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
            return (false, 100)
        }

        let isCharging = (description[kIOPSIsChargingKey] as? Bool) ?? false
        let percentage = (description[kIOPSCurrentCapacityKey] as? Int) ?? 100

        return (isCharging, percentage)
    }

    // MARK: - Wi-Fi Monitoring

    private func startWiFiMonitoring() {
        checkWiFi()
        wifiTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.checkWiFi()
        }
    }

    private func checkWiFi() {
        let wifiTriggers = triggers.filter { $0.type == .wifi && $0.isEnabled }
        guard !wifiTriggers.isEmpty else { return }

        let client = CWWiFiClient.shared()
        let interface = client.interface()
        let ssid = interface?.ssid()
        let isConnected = ssid != nil

        for trigger in wifiTriggers {
            var shouldActivate = false

            switch trigger.wifiCondition {
            case .connected:
                shouldActivate = isConnected
            case .disconnected:
                shouldActivate = !isConnected
            case .specificNetwork:
                if let networkName = trigger.wifiNetworkName {
                    shouldActivate = ssid == networkName
                }
            case .none:
                break
            }

            if shouldActivate, let presetID = trigger.presetID {
                onActivatePreset?(presetID)
            }
        }
    }

    // MARK: - Time Monitoring

    private func startTimeMonitoring() {
        timeTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkTime()
        }
    }

    private func checkTime() {
        let timeTriggers = triggers.filter { $0.type == .time && $0.isEnabled }
        guard !timeTriggers.isEmpty else { return }

        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentWeekday = calendar.component(.weekday, from: now)

        for trigger in timeTriggers {
            guard let hour = trigger.timeHour,
                  let minute = trigger.timeMinute else { continue }

            let dayMatches = trigger.timeDays?.contains(currentWeekday) ?? true
            let timeMatches = currentHour == hour && currentMinute == minute

            if dayMatches && timeMatches, let presetID = trigger.presetID {
                onActivatePreset?(presetID)
            }
        }
    }

    // MARK: - App Launch Monitoring

    private func startAppMonitoring() {
        let launchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleID = app.bundleIdentifier else { return }
            self?.handleAppEvent(bundleID: bundleID, launched: true)
        }
        appObservers.append(launchObserver)

        let terminateObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleID = app.bundleIdentifier else { return }
            self?.handleAppEvent(bundleID: bundleID, launched: false)
        }
        appObservers.append(terminateObserver)
    }

    private func handleAppEvent(bundleID: String, launched: Bool) {
        let appTriggers = triggers.filter { $0.type == .appLaunch && $0.isEnabled }

        for trigger in appTriggers {
            if trigger.appBundleIdentifier == bundleID, launched, let presetID = trigger.presetID {
                onActivatePreset?(presetID)
            }
        }
    }

    // MARK: - Persistence

    private func saveTriggers() {
        guard let data = try? JSONEncoder().encode(triggers) else { return }
        UserDefaults.standard.set(data, forKey: triggersKey)
    }

    private func loadTriggers() {
        guard let data = UserDefaults.standard.data(forKey: triggersKey),
              let decoded = try? JSONDecoder().decode([Trigger].self, from: data) else { return }
        triggers = decoded
    }

    deinit {
        stopMonitoring()
    }
}
