import SwiftUI

struct SettingsView: View {
    let appState: AppState

    var body: some View {
        TabView {
            MenuBarItemsSettingsView(appState: appState)
                .tabItem {
                    Label("Menu Bar Items", systemImage: "menubar.rectangle")
                }

            AppearanceSettingsView(settingsManager: appState.settingsManager)
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            HotkeySettingsView(appState: appState)
                .tabItem {
                    Label("Hotkeys", systemImage: "keyboard")
                }

            PresetsSettingsView(appState: appState)
                .tabItem {
                    Label("Presets", systemImage: "rectangle.stack")
                }

            TriggerSettingsView(appState: appState)
                .tabItem {
                    Label("Triggers", systemImage: "bolt")
                }

            GeneralSettingsView(settingsManager: appState.settingsManager)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
        }
        .frame(width: 580, height: 480)
    }
}
