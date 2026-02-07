import AppKit
import SwiftUI

@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let container: AppContainer
    private let viewModel: MainViewModel
    private let detailsViewModel: PRDetailsViewModel

    private let monitorWindowController = MonitorWindowController()
    private var settingsWindowController: NSWindowController?

    init(container: AppContainer) {
        self.container = container
        self.viewModel = MainViewModel(container: container)
        self.detailsViewModel = PRDetailsViewModel(container: container)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "point.3.connected.trianglepath.dotted", accessibilityDescription: "PRBar")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        popover.contentSize = NSSize(width: 920, height: 620)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverView(
            viewModel: viewModel,
            detailsViewModel: detailsViewModel,
            pinToMonitor: { [weak self] in self?.pinToMonitor() },
            openSettings: { [weak self] in self?.showSettingsWindow() },
            quitApp: { [weak self] in self?.quitApp() }
        ))
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func pinToMonitor() {
        viewModel.pinSelectedPRToMonitor()
        monitorWindowController.show(viewModel: viewModel, monitorStore: container.monitorStore)
    }

    private func showSettingsWindow() {
        let view = SettingsView(viewModel: viewModel)
        let hosting = NSHostingController(rootView: view)

        if settingsWindowController == nil {
            let window = NSWindow(contentRect: NSRect(x: 350, y: 350, width: 560, height: 620),
                                  styleMask: [.titled, .closable, .miniaturizable, .resizable],
                                  backing: .buffered,
                                  defer: false)
            window.title = "PRBar Settings"
            window.contentViewController = hosting
            settingsWindowController = NSWindowController(window: window)
        } else {
            settingsWindowController?.contentViewController = hosting
        }

        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func quitApp() {
        NSApp.terminate(nil)
    }
}
