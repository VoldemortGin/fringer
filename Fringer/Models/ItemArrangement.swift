import Foundation

/// Which section an item belongs to
enum MenuBarSection: String, Codable, CaseIterable {
    case visible
    case hidden
    case alwaysHidden
}

/// Persisted arrangement of a single menu bar item
struct ItemArrangement: Codable, Identifiable {
    var id: String { ownerName + (bundleIdentifier ?? "") }
    let ownerName: String
    let bundleIdentifier: String?
    var section: MenuBarSection
    var sortOrder: Int
}

/// The complete persisted state
struct ArrangementState: Codable {
    var items: [ItemArrangement]
    var version: Int = 1
}
