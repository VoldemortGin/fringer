import AppKit
import ApplicationServices

@Observable
final class PermissionsManager {
    private(set) var accessibilityGranted: Bool = false
    private(set) var screenRecordingGranted: Bool = false

    var allPermissionsGranted: Bool {
        accessibilityGranted && screenRecordingGranted
    }

    private var pollingTimer: Timer?

    init() {
        checkPermissions()
        startPolling()
    }

    func checkPermissions() {
        accessibilityGranted = AXIsProcessTrusted()
        screenRecordingGranted = checkScreenRecordingPermission()
    }

    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    func requestScreenRecording() {
        if #available(macOS 15.0, *) {
            CGRequestScreenCaptureAccess()
        } else {
            _ = CGWindowListCreateImage(
                CGRect(x: 0, y: 0, width: 1, height: 1),
                .optionOnScreenOnly,
                kCGNullWindowID,
                []
            )
        }
    }

    private func checkScreenRecordingPermission() -> Bool {
        if #available(macOS 15.0, *) {
            return CGPreflightScreenCaptureAccess()
        }
        guard let image = CGWindowListCreateImage(
            CGRect(x: 0, y: 0, width: 1, height: 1),
            .optionOnScreenOnly,
            kCGNullWindowID,
            []
        ) else { return false }
        return image.width > 0
    }

    func startPolling() {
        pollingTimer?.invalidate()
        guard !allPermissionsGranted else { return }
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            self.checkPermissions()
            if self.allPermissionsGranted {
                timer.invalidate()
                self.pollingTimer = nil
            }
        }
    }
}
