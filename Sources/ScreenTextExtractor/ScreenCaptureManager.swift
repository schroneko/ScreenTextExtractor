import Cocoa
@preconcurrency import ScreenCaptureKit

@MainActor
class ScreenCaptureManager: NSObject {
    
    func requestPermission() {
        // 起動時に権限を要求してダイアログを表示
        Task {
            do {
                let _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                print("Screen capture permission granted")
            } catch {
                print("Screen capture permission required: \(error)")
                // エラーが出てもOK（権限ダイアログが表示される）
            }
        }
    }
    
    private func showPermissionAlert() async {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = "Please grant screen recording permission in System Settings > Privacy & Security > Screen Recording"
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        
        let response = await alert.beginSheetModal(for: NSApp.mainWindow ?? NSWindow())
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
        }
    }
    
    func captureSelectedRegion(completion: @escaping @Sendable (CGImage?) -> Void) {
        let selectionWindow = ScreenSelectionWindow { [weak self] rect in
            guard let rect = rect else {
                completion(nil)
                return
            }
            
            Task {
                await self?.captureRect(rect, completion: completion)
            }
        }
        
        selectionWindow.showSelection()
    }
    
    private func captureRect(_ rect: CGRect, completion: @escaping @Sendable (CGImage?) -> Void) async {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let display = content.displays.first else {
                await showPermissionAlert()
                completion(nil)
                return
            }
            
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()
            config.sourceRect = rect
            config.width = Int(rect.width)
            config.height = Int(rect.height)
            config.scalesToFit = false
            
            let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
            completion(image)
            
        } catch {
            print("Screen capture error: \(error)")
            
            // 権限エラーの場合のみアラートを表示
            if error.localizedDescription.contains("permission") || 
               error.localizedDescription.contains("authorization") ||
               error.localizedDescription.contains("access") {
                await showPermissionAlert()
            }
            
            completion(nil)
        }
    }
}

@MainActor
class ScreenSelectionWindow: NSWindow {
    var startPoint: NSPoint?
    var endPoint: NSPoint?
    var isDragging = false
    private let selectionCallback: @Sendable (CGRect?) -> Void
    
    init(callback: @escaping @Sendable (CGRect?) -> Void) {
        self.selectionCallback = callback
        
        // 全画面をカバー（マルチディスプレイ対応）
        let screenFrame = NSScreen.screens.reduce(CGRect.zero) { result, screen in
            return result.union(screen.frame)
        }
        
        super.init(contentRect: screenFrame, styleMask: [.borderless], backing: .buffered, defer: false)
        
        self.level = .screenSaver + 1000 // より高いレベルで表示
        self.backgroundColor = NSColor.black.withAlphaComponent(0.4)
        self.isOpaque = true
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        
        let contentView = SelectionView(frame: screenFrame)
        contentView.selectionWindow = self
        contentView.wantsLayer = true
        self.contentView = contentView
    }
    
    func showSelection() {
        NSApp.activate(ignoringOtherApps: true)
        self.makeKeyAndOrderFront(nil)
        NSCursor.crosshair.set()
        
        // グローバルキーイベント監視を追加
        setupGlobalKeyMonitor()
    }
    
    private var keyMonitor: Any?
    
    private func setupGlobalKeyMonitor() {
        // 既存のモニターを削除
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        // ESCキーのグローバル監視
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape key
                self?.cancelSelection()
            }
        }
    }
    
    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            cancelSelection()
        }
    }
    
    func completeSelection(rect: CGRect) {
        removeKeyMonitor()
        NSCursor.arrow.set()
        self.orderOut(nil)
        selectionCallback(rect)
    }
    
    func cancelSelection() {
        removeKeyMonitor()
        NSCursor.arrow.set()
        self.orderOut(nil)
        selectionCallback(nil)
    }
    
    override func mouseDown(with event: NSEvent) {
        startPoint = event.locationInWindow
        endPoint = startPoint
        isDragging = false
        contentView?.needsDisplay = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        isDragging = true
        endPoint = event.locationInWindow
        contentView?.needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        guard let start = startPoint, let end = endPoint else {
            cancelSelection()
            return
        }
        
        // ドラッグしていない場合（単純なクリック）はキャンセル
        if !isDragging {
            cancelSelection()
            return
        }
        
        let rect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        
        if rect.width > 5 && rect.height > 5 {
            let screenRect = convertToScreenCoordinates(rect)
            completeSelection(rect: screenRect)
        } else {
            cancelSelection()
        }
    }
    
    private func convertToScreenCoordinates(_ rect: CGRect) -> CGRect {
        guard let screen = NSScreen.main else { return rect }
        
        let screenFrame = screen.frame
        return CGRect(
            x: rect.minX,
            y: screenFrame.height - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }
    
}

@MainActor
class SelectionView: NSView {
    weak var selectionWindow: ScreenSelectionWindow?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // 全体を暗く
        NSColor.black.withAlphaComponent(0.4).setFill()
        dirtyRect.fill()
        
        guard let window = selectionWindow else { return }
        
        // 選択範囲の描画
        if let start = window.startPoint, let end = window.endPoint, window.isDragging {
            let rect = NSRect(
                x: min(start.x, end.x),
                y: min(start.y, end.y),
                width: abs(end.x - start.x),
                height: abs(end.y - start.y)
            )
            
            // 選択範囲は透明に（暗くしない）
            NSColor.clear.setFill()
            NSBezierPath(rect: rect).fill()
            
            // 選択範囲の枠線（薄い白色）
            NSColor.white.withAlphaComponent(0.8).setStroke()
            let path = NSBezierPath(rect: rect)
            path.lineWidth = 1.0
            path.stroke()
            
            // 四隅に小さな角マーカー（Cmd+Shift+4風）
            drawCornerMarkers(for: rect)
        }
    }
    
    private func drawCornerMarkers(for rect: NSRect) {
        let markerSize: CGFloat = 10
        let markerThickness: CGFloat = 2
        
        NSColor.white.setStroke()
        
        // 左上
        let topLeft = NSBezierPath()
        topLeft.move(to: NSPoint(x: rect.minX, y: rect.minY + markerSize))
        topLeft.line(to: NSPoint(x: rect.minX, y: rect.minY))
        topLeft.line(to: NSPoint(x: rect.minX + markerSize, y: rect.minY))
        topLeft.lineWidth = markerThickness
        topLeft.stroke()
        
        // 右上
        let topRight = NSBezierPath()
        topRight.move(to: NSPoint(x: rect.maxX - markerSize, y: rect.minY))
        topRight.line(to: NSPoint(x: rect.maxX, y: rect.minY))
        topRight.line(to: NSPoint(x: rect.maxX, y: rect.minY + markerSize))
        topRight.lineWidth = markerThickness
        topRight.stroke()
        
        // 左下
        let bottomLeft = NSBezierPath()
        bottomLeft.move(to: NSPoint(x: rect.minX, y: rect.maxY - markerSize))
        bottomLeft.line(to: NSPoint(x: rect.minX, y: rect.maxY))
        bottomLeft.line(to: NSPoint(x: rect.minX + markerSize, y: rect.maxY))
        bottomLeft.lineWidth = markerThickness
        bottomLeft.stroke()
        
        // 右下
        let bottomRight = NSBezierPath()
        bottomRight.move(to: NSPoint(x: rect.maxX - markerSize, y: rect.maxY))
        bottomRight.line(to: NSPoint(x: rect.maxX, y: rect.maxY))
        bottomRight.line(to: NSPoint(x: rect.maxX, y: rect.maxY - markerSize))
        bottomRight.lineWidth = markerThickness
        bottomRight.stroke()
    }
}