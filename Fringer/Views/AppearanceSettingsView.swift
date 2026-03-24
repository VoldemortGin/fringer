import SwiftUI

struct AppearanceSettingsView: View {
    @Bindable var settingsManager: SettingsManager

    var body: some View {
        Form {
            Section("Menu Bar Spacing") {
                Picker("Icon spacing", selection: $settingsManager.iconSpacing) {
                    Text("Normal").tag(IconSpacing.normal)
                    Text("Small").tag(IconSpacing.small)
                    Text("None").tag(IconSpacing.none)
                }
                .pickerStyle(.segmented)
            }

            Section("Menu Bar Tint") {
                Toggle("Enable tint", isOn: $settingsManager.tintEnabled)

                if settingsManager.tintEnabled {
                    ColorPicker("Tint color", selection: $settingsManager.tintColor)

                    HStack {
                        Text("Opacity")
                        Slider(value: $settingsManager.tintOpacity, in: 0.05...0.8)
                        Text("\(Int(settingsManager.tintOpacity * 100))%")
                            .frame(width: 40)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Fringer Bar") {
                Toggle("Show Fringer Bar on hover", isOn: $settingsManager.showOnHover)

                HStack {
                    Text("Auto-dismiss delay")
                    Spacer()
                    Picker("", selection: $settingsManager.hideDelay) {
                        Text("0.5s").tag(0.5 as TimeInterval)
                        Text("1.0s").tag(1.0 as TimeInterval)
                        Text("1.5s").tag(1.5 as TimeInterval)
                        Text("2.0s").tag(2.0 as TimeInterval)
                        Text("3.0s").tag(3.0 as TimeInterval)
                        Text("5.0s").tag(5.0 as TimeInterval)
                    }
                    .frame(width: 100)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
