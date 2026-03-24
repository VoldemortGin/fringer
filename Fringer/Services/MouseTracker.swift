import AppKit

@Observable
final class MouseTracker {
    private var eventMonitor: Any?
    private var hideTimer: Timer?

    var onMenuBarHover: (() -> Void)?
    var onMenuBarExit: (() -> Void)?

    private var isInMenuBarArea = false
    private let menuBarHeight: CGFloat = 24

    func startTracking() {
        stopTracking()

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMoved(event)
        }
    }

    func stopTracking() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        hideTimer?.invalidate()
        hideTimer = nil
    }

    private func handleMouseMoved(_ event: NSEvent) {
        guard let screen = NSScreen.main else { return }

        let mouseLocation = NSEvent.mouseLocation
        let menuBarRect = NSRect(
            x: screen.frame.origin.x,
            y: screen.frame.maxY - menuBarHeight,
            width: screen.frame.width,
            height: menuBarHeight
        )

        let isNowInMenuBar = menuBarRect.contains(mouseLocation)

        if isNowInMenuBar && !isInMenuBarArea {
            isInMenuBarArea = true
            hideTimer?.invalidate()
            hideTimer = nil
            onMenuBarHover?()
        } else if !isNowInMenuBar && isInMenuBarArea {
            isInMenuBarArea = false
            onMenuBarExit?()
        }
    }

    func scheduleHide(after delay: TimeInterval, action: @escaping () -> Void) {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            action()
        }
    }

    func cancelHide() {
        hideTimer?.invalidate()
        hideTimer = nil
    }

    deinit {
        stopTracking()
    }
}
