import SwiftUI

struct GeneralSettingsView: View {
    @Bindable var settingsManager: SettingsManager

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch Fringer at login", isOn: $settingsManager.launchAtLogin)
            }

            Section("Behavior") {
                Toggle("Show hidden items on hover", isOn: $settingsManager.showOnHover)

                HStack {
                    Text("Auto-hide delay")
                    Spacer()
                    Picker("", selection: $settingsManager.hideDelay) {
                        Text("0.5s").tag(0.5 as TimeInterval)
                        Text("1.0s").tag(1.0 as TimeInterval)
                        Text("1.5s").tag(1.5 as TimeInterval)
                        Text("2.0s").tag(2.0 as TimeInterval)
                        Text("3.0s").tag(3.0 as TimeInterval)
                    }
                    .frame(width: 100)
                }

                Toggle("Reduce energy usage on battery", isOn: $settingsManager.reduceEnergyOnBattery)
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
