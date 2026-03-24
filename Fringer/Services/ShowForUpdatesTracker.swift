import AppKit
import CoreGraphics

@Observable
final class ShowForUpdatesTracker {
    /// Items that should temporarily be shown because they changed
    private(set) var temporarilyShownItems: Set<String> = []  // ownerName set

    private var previousImageHashes: [String: Int] = [:]  // ownerName -> hash
    private var hideTimers: [String: Timer] = [:]

    var showDuration: TimeInterval = 5.0

    /// Check if any hidden items have changed their appearance
    func checkForUpdates(items: [MenuBarItem], hiddenOwnerNames: Set<String>) {
        for item in items {
            guard hiddenOwnerNames.contains(item.ownerName) else { continue }

            let currentHash = imageHash(for: item)
            let previousHash = previousImageHashes[item.ownerName]

            if let previousHash, currentHash != previousHash {
                // Icon changed — temporarily show it
                temporarilyShow(ownerName: item.ownerName)
            }

            previousImageHashes[item.ownerName] = currentHash
        }
    }

    private func imageHash(for item: MenuBarItem) -> Int {
        guard let image = item.image,
              let tiffData = image.tiffRepresentation else { return 0 }
        return tiffData.hashValue
    }

    private func temporarilyShow(ownerName: String) {
        temporarilyShownItems.insert(ownerName)

        // Cancel existing timer
        hideTimers[ownerName]?.invalidate()

        // Set timer to re-hide
        hideTimers[ownerName] = Timer.scheduledTimer(withTimeInterval: showDuration, repeats: false) { [weak self] _ in
            self?.temporarilyShownItems.remove(ownerName)
            self?.hideTimers.removeValue(forKey: ownerName)
        }
    }

    func clearAll() {
        temporarilyShownItems.removeAll()
        hideTimers.values.forEach { $0.invalidate() }
        hideTimers.removeAll()
    }

    deinit {
        hideTimers.values.forEach { $0.invalidate() }
    }
}
