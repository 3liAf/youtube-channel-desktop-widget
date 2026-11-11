import AppKit
import SwiftUI
import Combine

@MainActor
public class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var desktopPanel: NSPanel?
    private var fetcher = ChannelFetcher()
    private var cancellables = Set<AnyCancellable>()
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent dock icon from showing
        NSApp.setActivationPolicy(.accessory)
        
        setupStatusItem()
        setupPopover()
        observeStats()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
            let image = NSImage(systemSymbolName: "play.rectangle.fill", accessibilityDescription: "YouTube")?
                .withSymbolConfiguration(config)
            
            button.image = image
            button.imagePosition = .imageLeading
            button.title = " 1 Sub"
            button.target = self
            button.action = #selector(togglePopover)
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 340)
        popover.behavior = .transient
        popover.animates = true
        
        let popoverView = PopoverView(
            fetcher: fetcher,
            onToggleDesktopWidget: { [weak self] in
                self?.toggleDesktopWidget()
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )
        
        popover.contentViewController = NSHostingController(rootView: popoverView)
    }
    
    private func observeStats() {
        fetcher.$stats
            .receive(on: RunLoop.main)
            .sink { [weak self] stats in
                guard let self = self, let button = self.statusItem.button else { return }
                let subShort = stats.subscribersText
                    .replacingOccurrences(of: " subscriber", with: "")
                    .replacingOccurrences(of: "s", with: "")
                button.title = " \(subShort) Sub"
            }
            .store(in: &cancellables)
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    private func toggleDesktopWidget() {
        if let panel = desktopPanel, panel.isVisible {
            panel.orderOut(nil)
            fetcher.showFloatingDesktopWidget = false
        } else {
            showDesktopWidget()
        }
    }
    
    private func showDesktopWidget() {
        if desktopPanel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 220, height: 110),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false
            panel.isMovableByWindowBackground = true
            
            let widgetView = DesktopWidgetView(fetcher: fetcher) { [weak self] in
                self?.desktopPanel?.orderOut(nil)
                self?.fetcher.showFloatingDesktopWidget = false
            }
            
            panel.contentViewController = NSHostingController(rootView: widgetView)
            
            // Position in top right corner of main screen
            if let screen = NSScreen.main {
                let screenRect = screen.visibleFrame
                let x = screenRect.maxX - 240
                let y = screenRect.maxY - 130
                panel.setFrameOrigin(NSPoint(x: x, y: y))
            }
            
            self.desktopPanel = panel
        }
        
        desktopPanel?.makeKeyAndOrderFront(nil)
        fetcher.showFloatingDesktopWidget = true
    }
}
