import AppKit
import CoreGraphics

struct MenuBarItem: Identifiable, Hashable {
    let id: UUID
    let windowID: CGWindowID
    let ownerPID: pid_t
    let ownerName: String
    let frame: CGRect
    let title: String?
    var image: NSImage?
    var isVisible: Bool

    static func == (lhs: MenuBarItem, rhs: MenuBarItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
