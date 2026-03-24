import SwiftUI

struct MenuBarItemsSettingsView: View {
    let appState: AppState

    private var visibleItems: [MenuBarItem] {
        appState.menuBarMonitor.items.filter {
            appState.settingsManager.getSection(for: $0.ownerName) == .visible
        }
    }

    private var hiddenItems: [MenuBarItem] {
        appState.menuBarMonitor.items.filter {
            appState.settingsManager.getSection(for: $0.ownerName) == .hidden
        }
    }

    private var alwaysHiddenItems: [MenuBarItem] {
        appState.menuBarMonitor.items.filter {
            appState.settingsManager.getSection(for: $0.ownerName) == .alwaysHidden
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !appState.permissionsManager.allPermissionsGranted {
                PermissionsView(permissionsManager: appState.permissionsManager)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ItemSectionView(
                            title: "Shown",
                            subtitle: "Always visible in the menu bar",
                            items: visibleItems,
                            targetSection: .visible,
                            settingsManager: appState.settingsManager
                        )

                        Divider()

                        ItemSectionView(
                            title: "Hidden",
                            subtitle: "Shown in the Fringer Bar on demand",
                            items: hiddenItems,
                            targetSection: .hidden,
                            settingsManager: appState.settingsManager
                        )

                        Divider()

                        ItemSectionView(
                            title: "Always Hidden",
                            subtitle: "Only accessible via search",
                            items: alwaysHiddenItems,
                            targetSection: .alwaysHidden,
                            settingsManager: appState.settingsManager
                        )
                    }
                    .padding()
                }

                HStack {
                    Button("Refresh") {
                        appState.menuBarMonitor.refresh()
                    }
                    Spacer()
                    Text("\(appState.menuBarMonitor.items.count) items detected")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }
}

struct ItemSectionView: View {
    let title: String
    let subtitle: String
    let items: [MenuBarItem]
    let targetSection: MenuBarSection
    let settingsManager: SettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if items.isEmpty {
                Text("No items")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(items) { item in
                    MenuBarItemRow(item: item, settingsManager: settingsManager)
                }
            }
        }
    }
}

struct MenuBarItemRow: View {
    let item: MenuBarItem
    let settingsManager: SettingsManager

    var body: some View {
        HStack(spacing: 10) {
            if let image = item.image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
            } else {
                Image(systemName: "app.dashed")
                    .frame(width: 18, height: 18)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(item.ownerName)
                    .font(.body)
                if let title = item.title {
                    Text(title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Picker("Section", selection: Binding(
                get: { settingsManager.getSection(for: item.ownerName) },
                set: { settingsManager.setSection($0, for: item.ownerName) }
            )) {
                Text("Show").tag(MenuBarSection.visible)
                Text("Hide").tag(MenuBarSection.hidden)
                Text("Always Hide").tag(MenuBarSection.alwaysHidden)
            }
            .pickerStyle(.segmented)
            .frame(width: 220)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.05))
        )
    }
}
