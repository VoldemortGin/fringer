import AppKit
import SwiftUI

final class FringerBarPanel: NSPanel {
    private var hostingView: NSHostingView<FringerBarContentView>?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 38),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        level = .statusBar
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        animationBehavior = .utilityWindow
    }

    func updateContent(items: [MenuBarItem], onItemClick: @escaping (MenuBarItem) -> Void) {
        let contentView = FringerBarContentView(items: items, onItemClick: onItemClick)
        if let hostingView {
            hostingView.rootView = contentView
        } else {
            let hosting = NSHostingView(rootView: contentView)
            self.contentView = hosting
            self.hostingView = hosting
        }

        // Resize based on item count
        let itemWidth: CGFloat = 36
        let padding: CGFloat = 16
        let width = max(CGFloat(items.count) * itemWidth + padding, 100)
        let frame = NSRect(x: 0, y: 0, width: width, height: 38)
        setContentSize(frame.size)
    }

    func showBelow(statusItem: NSStatusItem?) {
        if let button = statusItem?.button,
           let buttonWindow = button.window {
            let buttonRect = button.convert(button.bounds, to: nil)
            let screenRect = buttonWindow.convertToScreen(buttonRect)

            let x = screenRect.midX - frame.width / 2
            let y = screenRect.minY - frame.height - 4

            setFrameOrigin(NSPoint(x: x, y: y))
        } else if let screen = NSScreen.main {
            let x = screen.frame.midX - frame.width / 2
            let y = screen.frame.maxY - frame.height - 28
            setFrameOrigin(NSPoint(x: x, y: y))
        }
        orderFrontRegardless()
    }

    func dismiss() {
        orderOut(nil)
    }
}
