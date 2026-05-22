import SwiftUI

@main
struct FringerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Fringer", systemImage: "rectangle.topthird.inset.filled") {
            Button("Toggle Fringer Bar") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    appState.toggleFringerBar()
                }
            }

            Button("Search Menu Bar Items...") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    appState.showSearch()
                }
            }

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

            Button("Preferences...") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate()
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
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
