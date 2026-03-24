import SwiftUI

struct SearchPanelView: View {
    let items: [MenuBarItem]
    let onSelect: (MenuBarItem) -> Void
    let onDismiss: () -> Void

    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    private var filteredItems: [MenuBarItem] {
        if searchText.isEmpty { return items }
        return items.filter { item in
            item.ownerName.localizedCaseInsensitiveContains(searchText) ||
            (item.title?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search menu bar items...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .focused($isSearchFocused)
                    .onSubmit {
                        if let first = filteredItems.first {
                            onSelect(first)
                        }
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)

            if !filteredItems.isEmpty {
                Divider()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredItems) { item in
                            Button {
                                onSelect(item)
                            } label: {
                                HStack(spacing: 10) {
                                    if let image = item.image {
                                        Image(nsImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 16, height: 16)
                                    } else {
                                        Image(systemName: "app.dashed")
                                            .frame(width: 16, height: 16)
                                            .foregroundStyle(.secondary)
                                    }

                                    Text(item.ownerName)
                                        .font(.system(size: 13))

                                    if let title = item.title {
                                        Text(title)
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 200)
            } else if !searchText.isEmpty {
                Text("No items found")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .padding()
            }
        }
        .background(
            VisualEffectBlur(material: .popover, blendingMode: .behindWindow)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
        )
        .frame(width: 350)
        .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
        .onAppear {
            isSearchFocused = true
        }
        .onExitCommand {
            onDismiss()
        }
    }
}
