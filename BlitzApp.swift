import SwiftUI
import AppKit

class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: FloatingPanel!
    var statusItem: NSStatusItem!
    var globalEventMonitor: Any?
    var localEventMonitor: Any?
    var store: NoteStore!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        store = NoteStore()
        let contentView = ContentView().environmentObject(store)

        window = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 380),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        window.contentView = hostingView
        
        setupMenuBarIcon()
        setupShortcuts()
    }
    
    func setupShortcuts() {
        let mask: NSEvent.ModifierFlags = [.command, .shift]
        
        let keyCode: UInt16 = 37
        
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == keyCode && event.modifierFlags.intersection(.deviceIndependentFlagsMask) == mask {
                self?.togglePanel()
            }
        }
        
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == keyCode && event.modifierFlags.intersection(.deviceIndependentFlagsMask) == mask {
                self?.togglePanel()
                return nil
            }
            return event
        }
    }
    
    @objc func togglePanel() {
        if window.isVisible && NSApp.isActive {
            window.orderOut(nil)
        } else {
            let mouseLocation = NSEvent.mouseLocation
            let panelSize = window.frame.size
            var origin = NSPoint(x: mouseLocation.x - (panelSize.width / 2), y: mouseLocation.y - (panelSize.height / 2))
            
            if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) ?? NSScreen.main {
                let screenRect = screen.visibleFrame
                origin.x = max(screenRect.minX, min(origin.x, screenRect.maxX - panelSize.width))
                origin.y = max(screenRect.minY, min(origin.y, screenRect.maxY - panelSize.height))
            }
            
            window.setFrameOrigin(origin)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func setupMenuBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "Blitz")
            button.action = #selector(statusBarButtonClicked(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }
    }
    
    @objc func statusBarButtonClicked(sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(withTitle: "Quit Blitz", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            togglePanel()
        }
    }
}

@main
struct BlitzApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings { EmptyView() }
    }
}
