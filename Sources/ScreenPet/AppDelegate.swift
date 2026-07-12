import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayController: OverlayWindowController?
    private var statusItem: NSStatusItem?
    private var markerMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        installStatusItem()

        let overlayController = OverlayWindowController()
        self.overlayController = overlayController
        overlayController.setMarkerVisible(true)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)
    }

    private func installStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.statusItem = statusItem

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "circle.dashed",
                accessibilityDescription: "ScreenPet"
            )
            button.toolTip = "ScreenPet"
        }

        let menu = NSMenu()

        let markerMenuItem = NSMenuItem(
            title: "Hide Marker",
            action: #selector(toggleMarker(_:)),
            keyEquivalent: ""
        )
        markerMenuItem.target = self
        menu.addItem(markerMenuItem)
        self.markerMenuItem = markerMenuItem

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit ScreenPet",
            action: #selector(quit(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc
    private func toggleMarker(_ sender: Any?) {
        guard let overlayController else { return }

        let shouldShow = !overlayController.isMarkerVisible
        overlayController.setMarkerVisible(shouldShow)
        markerMenuItem?.title = shouldShow ? "Hide Marker" : "Show Marker"
    }

    @objc
    private func quit(_ sender: Any?) {
        NSApplication.shared.terminate(nil)
    }

    @objc
    private func screenParametersDidChange(_ notification: Notification) {
        overlayController?.reposition()
    }
}
