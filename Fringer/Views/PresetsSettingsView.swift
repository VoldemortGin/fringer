import SwiftUI

struct PresetsSettingsView: View {
    let appState: AppState
    @State private var newPresetName = ""
    @State private var showingNewPreset = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Presets")
                    .font(.headline)
                Spacer()
                Button {
                    showingNewPreset = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            if appState.presetManager.presets.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No presets yet")
                        .foregroundStyle(.secondary)
                    Text("Create a preset to save your current menu bar arrangement")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(appState.presetManager.presets) { preset in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(preset.name)
                                        .font(.body)
                                    if appState.presetManager.activePresetID == preset.id {
                                        Text("Active")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor.opacity(0.15))
                                            .clipShape(Capsule())
                                    }
                                }
                                Text("\(preset.arrangements.count) items configured")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button("Activate") {
                                appState.presetManager.activatePreset(preset, settingsManager: appState.settingsManager)
                            }
                            .disabled(appState.presetManager.activePresetID == preset.id)
                            .controlSize(.small)

                            Button(role: .destructive) {
                                appState.presetManager.deletePreset(preset)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .controlSize(.small)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingNewPreset) {
            VStack(spacing: 16) {
                Text("New Preset")
                    .font(.headline)
                TextField("Preset name", text: $newPresetName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
                HStack {
                    Button("Cancel") {
                        showingNewPreset = false
                        newPresetName = ""
                    }
                    .keyboardShortcut(.cancelAction)
                    Button("Create") {
                        if !newPresetName.isEmpty {
                            _ = appState.presetManager.createPreset(
                                name: newPresetName,
                                from: appState.settingsManager
                            )
                            showingNewPreset = false
                            newPresetName = ""
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(newPresetName.isEmpty)
                }
            }
            .padding(24)
        }
    }
}
