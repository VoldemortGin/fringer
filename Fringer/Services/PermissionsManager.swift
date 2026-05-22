import AppKit

@Observable
final class PermissionsManager {
    private(set) var screenRecordingGranted: Bool = false

    var allPermissionsGranted: Bool {
        screenRecordingGranted
    }

    private var pollingTimer: Timer?

    init() {
        checkPermissions()
        startPolling()
    }

    func checkPermissions() {
        screenRecordingGranted = checkScreenRecordingPermission()
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
        startPollingForScreenRecording()
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

    private func startPollingForScreenRecording() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            if self.checkScreenRecordingPermission() {
                self.screenRecordingGranted = true
                timer.invalidate()
            }
        }
    }
}
