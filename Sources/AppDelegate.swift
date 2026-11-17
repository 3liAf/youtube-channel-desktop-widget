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
        // Prevent dock icon from showing (pure menu bar agent)
        NSApp.setActivationPolicy(.accessory)
        
        setupStatusItem()
        setupPopover()
        observeStats()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
            let image = NSImage(systemSymbolName: "play.rectangle.fill", accessibilityDescription: "YouTube Stats")?
                .withSymbolConfiguration(config)
            
            button.image = image
            button.imagePosition = .imageLeading
            button.target = self
            button.action = #selector(togglePopover)
            updateMenuBarTitle()
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 490)
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
        
        let hostingController = NSHostingController(rootView: popoverView)
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        popover.contentViewController = hostingController
    }
    
    private func observeStats() {
        fetcher.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateMenuBarTitle()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateMenuBarTitle() {
        guard let button = statusItem.button else { return }
        
        switch fetcher.menuBarMode {
        case .iconOnly:
            button.title = ""
            
        case .compact:
            if fetcher.isCombinedView {
                button.title = " \(fetcher.combinedStats.formattedSubscribers)"
            } else if let active = fetcher.activeChannel {
                let subShort = active.subscribersText
                    .replacingOccurrences(of: " subscriber", with: "")
                    .replacingOccurrences(of: "s", with: "")
                button.title = " \(subShort)"
            } else {
                button.title = " --"
            }
            
        case .combinedTotal:
            let subs = fetcher.combinedStats.formattedSubscribers
            let chCount = fetcher.channels.count
            button.title = " \(subs) (\(chCount) Ch)"
            
        case .activeChannel:
            if fetcher.isCombinedView {
                let subs = fetcher.combinedStats.formattedSubscribers
                button.title = " Total: \(subs)"
            } else if let active = fetcher.activeChannel {
                let subShort = active.subscribersText
                    .replacingOccurrences(of: " subscriber", with: "")
                    .replacingOccurrences(of: "s", with: "")
                let plural = (subShort == "1") ? "Sub" : "Subs"
                
                if fetcher.showHandleInMenuBar && !active.handle.isEmpty {
                    button.title = " \(active.handle): \(subShort) \(plural)"
                } else {
                    button.title = " \(subShort) \(plural)"
                }
            } else {
                button.title = " --"
            }
        }
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
                contentRect: NSRect(x: 0, y: 0, width: 230, height: 120),
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
                let x = screenRect.maxX - 250
                let y = screenRect.maxY - 140
                panel.setFrameOrigin(NSPoint(x: x, y: y))
            }
            
            self.desktopPanel = panel
        }
        
        desktopPanel?.makeKeyAndOrderFront(nil)
        fetcher.showFloatingDesktopWidget = true
    }
}
