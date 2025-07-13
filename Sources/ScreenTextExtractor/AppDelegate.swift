import Cocoa

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem: NSStatusItem?
    var hotkeyManager: HotkeyManager?
    var screenCaptureManager: ScreenCaptureManager?
    var ocrManager: OCRManager?
    var clipboardManager: ClipboardManager?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupStatusBar()
        setupManagers()
        setupHotkey()
        requestScreenCapturePermission()
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.text.viewfinder", accessibilityDescription: "Screen Text Extractor")
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "About ScreenTextExtractor", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    private func setupManagers() {
        screenCaptureManager = ScreenCaptureManager()
        ocrManager = OCRManager()
        clipboardManager = ClipboardManager()
        hotkeyManager = HotkeyManager { [weak self] in
            self?.captureAndProcessText()
        }
    }
    
    private func setupHotkey() {
        hotkeyManager?.registerHotkey()
    }
    
    private func requestScreenCapturePermission() {
        screenCaptureManager?.requestPermission()
    }
    
    @objc private func statusBarButtonClicked(_ sender: AnyObject?) {
        captureAndProcessText()
    }
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "ScreenTextExtractor"
        alert.informativeText = "Version 1.0\n\nCapture text from screen using OCR.\nPress Cmd+Shift+2 to start capture."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func captureAndProcessText() {
        guard let screenCaptureManager = screenCaptureManager,
              let ocrManager = ocrManager,
              let clipboardManager = clipboardManager else {
            showNotification("Error: Managers not initialized")
            return
        }
        
        screenCaptureManager.captureSelectedRegion { [weak self] image in
            DispatchQueue.main.async {
                guard let image = image else {
                    self?.showNotification("Capture cancelled or failed")
                    return
                }
                
                ocrManager.extractText(from: image) { text in
                    DispatchQueue.main.async {
                        if text.isEmpty {
                            self?.showNotification("No text found")
                        } else {
                            clipboardManager.copyToClipboard(text)
                            self?.showNotification("Text copied to clipboard")
                        }
                    }
                }
            }
        }
    }
    
    private func showNotification(_ message: String) {
        let notification = NSUserNotification()
        notification.title = "ScreenTextExtractor"
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        hotkeyManager?.unregisterHotkey()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return false
    }
}