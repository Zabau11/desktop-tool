import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayController: OverlayWindowController?
    private let inputMonitor = InputMonitor()
    private var statusItem: NSStatusItem?
    private var petMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        installStatusItem()
        inputMonitor.start()

        let overlayController = OverlayWindowController()
        self.overlayController = overlayController
        inputMonitor.onMessage = { [weak overlayController] message in
            overlayController?.showDiagnosticMessage(message)
        }
        overlayController.setPetVisible(true)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        inputMonitor.stop()
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

        let petMenuItem = NSMenuItem(
            title: "Hide Pet",
            action: #selector(togglePet(_:)),
            keyEquivalent: ""
        )
        petMenuItem.target = self
        menu.addItem(petMenuItem)
        self.petMenuItem = petMenuItem

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
    private func togglePet(_ sender: Any?) {
        guard let overlayController else { return }

        let shouldShow = !overlayController.isPetVisible
        overlayController.setPetVisible(shouldShow)
        petMenuItem?.title = shouldShow ? "Hide Pet" : "Show Pet"
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
