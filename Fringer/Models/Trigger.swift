import Foundation

/// Types of triggers that can activate a preset
enum TriggerType: String, Codable, CaseIterable, Identifiable {
    case battery
    case wifi
    case time
    case appLaunch

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .battery: return "Battery"
        case .wifi: return "Wi-Fi"
        case .time: return "Time"
        case .appLaunch: return "App Launch"
        }
    }

    var systemImage: String {
        switch self {
        case .battery: return "battery.100"
        case .wifi: return "wifi"
        case .time: return "clock"
        case .appLaunch: return "app.badge"
        }
    }
}

enum BatteryCondition: String, Codable, CaseIterable {
    case onBattery = "On Battery"
    case charging = "Charging"
    case belowPercent = "Below Percentage"
}

enum WiFiCondition: String, Codable, CaseIterable {
    case connected = "Connected"
    case disconnected = "Disconnected"
    case specificNetwork = "Specific Network"
}

struct Trigger: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var type: TriggerType
    var isEnabled: Bool
    var presetID: UUID?  // Which preset to activate

    // Battery trigger settings
    var batteryCondition: BatteryCondition?
    var batteryThreshold: Int?  // Percentage for belowPercent

    // Wi-Fi trigger settings
    var wifiCondition: WiFiCondition?
    var wifiNetworkName: String?

    // Time trigger settings
    var timeHour: Int?
    var timeMinute: Int?
    var timeDays: Set<Int>?  // 1=Sun, 2=Mon, ... 7=Sat

    // App launch trigger settings
    var appBundleIdentifier: String?
    var appName: String?

    init(name: String, type: TriggerType) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.isEnabled = true

        switch type {
        case .battery:
            self.batteryCondition = .onBattery
        case .wifi:
            self.wifiCondition = .connected
        case .time:
            self.timeHour = 9
            self.timeMinute = 0
            self.timeDays = Set(1...7)
        case .appLaunch:
            break
        }
    }
}
