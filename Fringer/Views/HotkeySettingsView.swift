import SwiftUI

struct HotkeySettingsView: View {
    let appState: AppState

    var body: some View {
        Form {
            Section("Global Hotkeys") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Toggle Fringer Bar")
                        Text("Show/hide hidden menu bar items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("Cmd + Shift + B")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("Quick Search")
                        Text("Search and activate any menu bar item")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("Cmd + Option + B")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            Section {
                Text("Custom hotkey configuration coming soon")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
