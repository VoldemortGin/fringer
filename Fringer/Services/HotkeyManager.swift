import AppKit
import Carbon

@Observable
final class HotkeyManager {
    struct Hotkey: Equatable {
        let keyCode: UInt32
        let modifiers: UInt32

        static let toggleFringerBar = Hotkey(
            keyCode: UInt32(kVK_ANSI_B),
            modifiers: UInt32(cmdKey | shiftKey)
        )

        static let quickSearch = Hotkey(
            keyCode: UInt32(kVK_ANSI_B),
            modifiers: UInt32(cmdKey | optionKey)
        )
    }

    private var toggleBarHotkeyRef: EventHotKeyRef?
    private var searchHotkeyRef: EventHotKeyRef?

    var onToggleFringerBar: (() -> Void)?
    var onQuickSearch: (() -> Void)?

    private static var shared: HotkeyManager?

    func registerHotkeys() {
        HotkeyManager.shared = self

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                guard let event else { return OSStatus(eventNotHandledErr) }

                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                switch hotKeyID.id {
                case 1:
                    HotkeyManager.shared?.onToggleFringerBar?()
                case 2:
                    HotkeyManager.shared?.onQuickSearch?()
                default:
                    break
                }

                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )

        // Register Cmd+Shift+B for toggle
        var toggleID = EventHotKeyID(signature: OSType(0x4652_4E47), id: 1) // "FRNG"
        RegisterEventHotKey(
            Hotkey.toggleFringerBar.keyCode,
            Hotkey.toggleFringerBar.modifiers,
            toggleID,
            GetApplicationEventTarget(),
            0,
            &toggleBarHotkeyRef
        )

        // Register Cmd+Option+B for search
        var searchID = EventHotKeyID(signature: OSType(0x4652_4E47), id: 2)
        RegisterEventHotKey(
            Hotkey.quickSearch.keyCode,
            Hotkey.quickSearch.modifiers,
            searchID,
            GetApplicationEventTarget(),
            0,
            &searchHotkeyRef
        )
    }

    func unregisterHotkeys() {
        if let ref = toggleBarHotkeyRef {
            UnregisterEventHotKey(ref)
            toggleBarHotkeyRef = nil
        }
        if let ref = searchHotkeyRef {
            UnregisterEventHotKey(ref)
            searchHotkeyRef = nil
        }
    }

    deinit {
        unregisterHotkeys()
    }
}
