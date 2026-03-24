import AppKit
import SwiftUI

final class SearchPanel: NSPanel {
    private var hostingView: NSHostingView<SearchPanelView>?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 50),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false  // Shadow is in SwiftUI
        isMovableByWindowBackground = false
        hidesOnDeactivate = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    func show(items: [MenuBarItem], onSelect: @escaping (MenuBarItem) -> Void, onDismiss: @escaping () -> Void) {
        let view = SearchPanelView(
            items: items,
            onSelect: { [weak self] item in
                onSelect(item)
                self?.dismiss()
            },
            onDismiss: { [weak self] in
                onDismiss()
                self?.dismiss()
            }
        )

        let hosting = NSHostingView(rootView: view)
        contentView = hosting
        hostingView = hosting

        // Position at top center of screen
        if let screen = NSScreen.main {
            let x = screen.frame.midX - 175
            let y = screen.frame.maxY - 100
            setFrameOrigin(NSPoint(x: x, y: y))
        }

        makeKeyAndOrderFront(nil)
    }

    func dismiss() {
        orderOut(nil)
    }

    override var canBecomeKey: Bool { true }
}
