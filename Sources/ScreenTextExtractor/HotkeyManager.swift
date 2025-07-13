import Cocoa
import MASShortcut

class HotkeyManager {
    private let hotkeyCallback: () -> Void
    
    init(callback: @escaping () -> Void) {
        self.hotkeyCallback = callback
    }
    
    func registerHotkey() {
        let shortcut = MASShortcut(keyCode: Int(kVK_ANSI_2), modifierFlags: [.command, .shift])
        
        MASShortcutMonitor.shared().register(shortcut, withAction: { [weak self] in
            self?.hotkeyCallback()
        })
        
        print("Hotkey registered successfully: Cmd+Shift+2")
    }
    
    func unregisterHotkey() {
        MASShortcutMonitor.shared().unregisterAllShortcuts()
        print("Hotkey unregistered")
    }
    
    deinit {
        unregisterHotkey()
    }
}