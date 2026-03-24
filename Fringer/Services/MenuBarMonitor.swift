import AppKit
import Combine

@Observable
final class MenuBarMonitor {
    private(set) var items: [MenuBarItem] = []
    private let detector = MenuBarItemDetector()
    private var timer: Timer?

    var onItemsUpdated: (([MenuBarItem]) -> Void)?

    var isMonitoring: Bool { timer != nil }

    func startMonitoring(interval: TimeInterval = 2.0) {
        stopMonitoring()
        items = detector.discoverItems()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        items = detector.discoverItems()
        onItemsUpdated?(items)
    }

    func clickItem(_ item: MenuBarItem) {
        detector.clickItem(item)
    }
}
