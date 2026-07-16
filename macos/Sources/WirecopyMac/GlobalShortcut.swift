import Carbon
import Foundation

final class GlobalShortcut {
    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?

    @discardableResult
    func register() -> OSStatus {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, _ in
                NSLog("Wirecopy received the global shortcut")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .wirecopyShortcut, object: nil)
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &handler
        )
        guard handlerStatus == noErr else {
            NSLog("Wirecopy could not install its hotkey handler: %d", handlerStatus)
            return handlerStatus
        }

        let identifier = EventHotKeyID(signature: fourCharacterCode("WCPY"), id: 1)
        let registrationStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_C),
            UInt32(controlKey | optionKey),
            identifier,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )
        NSLog("Wirecopy hotkey registration finished: %d", registrationStatus)
        return registrationStatus
    }

    deinit {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let handler { RemoveEventHandler(handler) }
    }

    private func fourCharacterCode(_ value: String) -> FourCharCode {
        value.utf8.reduce(0) { ($0 << 8) + FourCharCode($1) }
    }
}
