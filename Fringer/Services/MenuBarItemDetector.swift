import AppKit
import CoreGraphics
import ApplicationServices

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

            let title = getAccessibilityTitle(for: ownerPID)
            let image = captureItemImage(windowID: windowID, frame: frame)
            let id = knownItems[windowID]?.id ?? UUID()

            let item = MenuBarItem(
                id: id,
                windowID: windowID,
                ownerPID: ownerPID,
                ownerName: ownerName,
                frame: frame,
                title: title,
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

    private func getAccessibilityTitle(for pid: pid_t) -> String? {
        let appElement = AXUIElementCreateApplication(pid)

        var menuBar: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXMenuBarAttribute as CFString, &menuBar)
        guard result == .success else { return nil }

        var children: CFTypeRef?
        // swiftlint:disable:next force_cast
        AXUIElementCopyAttributeValue(menuBar as! AXUIElement, kAXChildrenAttribute as CFString, &children)

        if let items = children as? [AXUIElement], let first = items.first {
            var title: CFTypeRef?
            AXUIElementCopyAttributeValue(first, kAXTitleAttribute as CFString, &title)
            return title as? String
        }

        return nil
    }

    func clickItem(_ item: MenuBarItem) {
        let appElement = AXUIElementCreateApplication(item.ownerPID)

        var extrasMenuBar: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, "AXExtrasMenuBar" as CFString, &extrasMenuBar)

        if result == .success, let extrasMenuBar {
            let menuBar = extrasMenuBar as! AXUIElement // swiftlint:disable:this force_cast
            var children: CFTypeRef?
            AXUIElementCopyAttributeValue(menuBar, kAXChildrenAttribute as CFString, &children)
            if let items = children as? [AXUIElement] {
                for axItem in items {
                    AXUIElementPerformAction(axItem, kAXPressAction as CFString)
                    return
                }
            }
        }

        let clickPoint = CGPoint(
            x: item.frame.midX,
            y: item.frame.midY
        )

        let mouseDown = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: clickPoint,
            mouseButton: .left
        )
        let mouseUp = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: clickPoint,
            mouseButton: .left
        )

        mouseDown?.post(tap: .cghidEventTap)
        mouseUp?.post(tap: .cghidEventTap)
    }
}
