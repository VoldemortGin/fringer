import AppKit
import CoreGraphics

final class MenuBarItemDetector {
    private var knownItems: [CGWindowID: MenuBarItem] = [:]

    func discoverItems() -> [MenuBarItem] {
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return []
        }

        let myPID = ProcessInfo.processInfo.processIdentifier

        var items: [MenuBarItem] = []

        for window in windowList {
            guard let layer = window[kCGWindowLayer as String] as? Int,
                  layer == 25,
                  let windowID = window[kCGWindowNumber as String] as? CGWindowID,
                  let ownerPID = window[kCGWindowOwnerPID as String] as? pid_t,
                  ownerPID != myPID,
                  let ownerName = window[kCGWindowOwnerName as String] as? String,
                  let boundsDict = window[kCGWindowBounds as String] as? [String: CGFloat]
            else { continue }

            let frame = CGRect(
                x: boundsDict["X"] ?? 0,
                y: boundsDict["Y"] ?? 0,
                width: boundsDict["Width"] ?? 0,
                height: boundsDict["Height"] ?? 0
            )

            guard frame.width > 1 else { continue }

            let image = captureItemImage(windowID: windowID, frame: frame)
            let id = knownItems[windowID]?.id ?? UUID()

            let item = MenuBarItem(
                id: id,
                windowID: windowID,
                ownerPID: ownerPID,
                ownerName: ownerName,
                frame: frame,
                title: ownerName,
                image: image,
                isVisible: true
            )

            items.append(item)
        }

        items.sort { $0.frame.origin.x < $1.frame.origin.x }

        knownItems = Dictionary(uniqueKeysWithValues: items.map { ($0.windowID, $0) })

        return items
    }

    private func captureItemImage(windowID: CGWindowID, frame: CGRect) -> NSImage? {
        guard let cgImage = CGWindowListCreateImage(
            frame,
            .optionIncludingWindow,
            windowID,
            [.boundsIgnoreFraming, .bestResolution]
        ) else { return nil }

        return NSImage(cgImage: cgImage, size: NSSize(width: frame.width, height: frame.height))
    }

    func clickItem(_ item: MenuBarItem) {
        guard let app = NSRunningApplication(processIdentifier: item.ownerPID) else { return }
        if #available(macOS 14.0, *) {
            app.activate()
        } else {
            app.activate(options: [.activateIgnoringOtherApps])
        }
    }
}
