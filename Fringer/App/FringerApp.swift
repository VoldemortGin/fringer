import SwiftUI

@main
struct FringerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()
    @Environment(\.openSettings) private var openSettingsAction

    var body: some Scene {
        MenuBarExtra("Fringer", systemImage: "rectangle.topthird.inset.filled") {
            Button("Toggle Fringer Bar") {
                appState.toggleFringerBar()
            }
            .keyboardShortcut("b", modifiers: [.command, .shift])

            Button("Search Menu Bar Items...") {
                appState.showSearch()
            }
            .keyboardShortcut("b", modifiers: [.command, .option])

            Divider()

            if !appState.presetManager.presets.isEmpty {
                Menu("Presets") {
                    ForEach(appState.presetManager.presets) { preset in
                        Button {
                            appState.presetManager.activatePreset(preset, settingsManager: appState.settingsManager)
                        } label: {
                            if appState.presetManager.activePresetID == preset.id {
                                Text("\u{2713} \(preset.name)")
                            } else {
                                Text(preset.name)
                            }
                        }
                    }
                }
                Divider()
            }

            SettingsLink {
                Text("Preferences...")
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit Fringer") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }

        Settings {
            SettingsView(appState: appState)
        }
    }
}
