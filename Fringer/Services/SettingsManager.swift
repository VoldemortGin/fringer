import Foundation
import ServiceManagement
import SwiftUI

enum IconSpacing: String, Codable, CaseIterable {
    case normal
    case small
    case none
}

@Observable
final class SettingsManager {
    // General settings
    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update launch at login: \(error)")
            }
        }
    }

    var showOnHover: Bool {
        get { UserDefaults.standard.bool(forKey: "showOnHover") }
        set { UserDefaults.standard.set(newValue, forKey: "showOnHover") }
    }

    var hideDelay: TimeInterval {
        get { UserDefaults.standard.double(forKey: "hideDelay").nonZero ?? 1.5 }
        set { UserDefaults.standard.set(newValue, forKey: "hideDelay") }
    }

    var reduceEnergyOnBattery: Bool {
        get { UserDefaults.standard.bool(forKey: "reduceEnergyOnBattery") }
        set { UserDefaults.standard.set(newValue, forKey: "reduceEnergyOnBattery") }
    }

    // Appearance settings
    var iconSpacing: IconSpacing {
        get {
            guard let raw = UserDefaults.standard.string(forKey: "iconSpacing"),
                  let val = IconSpacing(rawValue: raw) else { return .normal }
            return val
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "iconSpacing") }
    }

    var tintEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "tintEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "tintEnabled") }
    }

    var tintColor: Color {
        get {
            guard let data = UserDefaults.standard.data(forKey: "tintColor"),
                  let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) else {
                return .blue
            }
            return Color(nsColor: nsColor)
        }
        set {
            let nsColor = NSColor(newValue)
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: true) {
                UserDefaults.standard.set(data, forKey: "tintColor")
            }
        }
    }

    var tintOpacity: Double {
        get {
            let val = UserDefaults.standard.double(forKey: "tintOpacity")
            return val == 0 ? 0.15 : val
        }
        set { UserDefaults.standard.set(newValue, forKey: "tintOpacity") }
    }

    // Item arrangement persistence
    private let arrangementKey = "itemArrangement"
    private var cachedArrangement: ArrangementState?
    private var arrangementLoaded = false

    func saveArrangement(_ state: ArrangementState) {
        cachedArrangement = state
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: arrangementKey)
    }

    func loadArrangement() -> ArrangementState? {
        if arrangementLoaded { return cachedArrangement }
        arrangementLoaded = true
        guard let data = UserDefaults.standard.data(forKey: arrangementKey) else { return nil }
        cachedArrangement = try? JSONDecoder().decode(ArrangementState.self, from: data)
        return cachedArrangement
    }

    func getSection(for ownerName: String) -> MenuBarSection {
        guard let state = loadArrangement() else { return .visible }
        return state.items.first(where: { $0.ownerName == ownerName })?.section ?? .visible
    }

    func setSection(_ section: MenuBarSection, for ownerName: String) {
        var state = loadArrangement() ?? ArrangementState(items: [])
        if let index = state.items.firstIndex(where: { $0.ownerName == ownerName }) {
            state.items[index].section = section
        } else {
            let arrangement = ItemArrangement(
                ownerName: ownerName,
                bundleIdentifier: nil,
                section: section,
                sortOrder: state.items.count
            )
            state.items.append(arrangement)
        }
        saveArrangement(state)
    }
}

private extension Double {
    var nonZero: Double? {
        self == 0 ? nil : self
    }
}
