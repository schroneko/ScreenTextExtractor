import Cocoa

@MainActor
class ClipboardManager {
    
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        print("Copied to clipboard: \(text.prefix(50))...")
    }
    
    func getClipboardContent() -> String? {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string)
    }
}