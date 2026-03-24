import Foundation

struct Preset: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var arrangements: [String: MenuBarSection]  // ownerName -> section
    var isDefault: Bool
    var createdAt: Date

    init(name: String, arrangements: [String: MenuBarSection] = [:], isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.arrangements = arrangements
        self.isDefault = isDefault
        self.createdAt = Date()
    }
}
