import SwiftUI
import AppKit

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var globalMonitor: Any?
    var localMonitor: Any?
    let appState = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            if let icon = NSImage(named: "AppIcon") ?? NSApp.applicationIconImage {
                let size = NSSize(width: 18, height: 18)
                let resized = NSImage(size: size, flipped: false) { rect in
                    icon.draw(in: rect)
                    return true
                }
                resized.isTemplate = false
                button.image = resized
            }
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 580)
        popover.behavior = .applicationDefined
        popover.animates = false
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPopover().environmentObject(appState)
        )
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            closePopover()
        } else {
            // Anchor to the status button's screen, not the main window's screen
            button.window?.makeKeyAndOrderFront(nil)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

            // Make the popover's own window key — avoid NSApp.activate which
            // can pull focus to whichever screen has the main window
            popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)

            globalMonitor = NSEvent.addGlobalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown]
            ) { [weak self] _ in
                self?.closePopover()
            }
            localMonitor = NSEvent.addLocalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown]
            ) { [weak self] event in
                guard let self = self else { return event }
                if let popoverWindow = self.popover.contentViewController?.view.window,
                   event.window != popoverWindow {
                    self.closePopover()
                }
                return event
            }
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
}
