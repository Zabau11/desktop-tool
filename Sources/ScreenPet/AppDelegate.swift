import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayController: OverlayWindowController?
    private var statusItem: NSStatusItem?
    private var petMenuItem: NSMenuItem?
    private var signalMenu: NSMenu?

    func applicationDidFinishLaunching(_ notification: Notification) {
        installStatusItem()
        let overlayController = OverlayWindowController()
        self.overlayController = overlayController
        overlayController.setPetVisible(true)
        overlayController.setUserSignal(.calm)

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

        let petMenuItem = NSMenuItem(
            title: "Hide Pet",
            action: #selector(togglePet(_:)),
            keyEquivalent: ""
        )
        petMenuItem.target = self
        menu.addItem(petMenuItem)
        self.petMenuItem = petMenuItem

        let signalItem = NSMenuItem(title: "User Signal", action: nil, keyEquivalent: "")
        let signalMenu = NSMenu(title: "User Signal")
        for signal in UserSignal.allCases {
            let item = NSMenuItem(
                title: signal.displayName,
                action: #selector(selectUserSignal(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = signal.rawValue
            item.state = signal == .calm ? .on : .off
            signalMenu.addItem(item)
        }
        signalItem.submenu = signalMenu
        menu.addItem(signalItem)
        self.signalMenu = signalMenu

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
    private func selectUserSignal(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let signal = UserSignal(rawValue: rawValue)
        else { return }

        overlayController?.setUserSignal(signal)
        signalMenu?.items.forEach {
            $0.state = ($0.representedObject as? String) == signal.rawValue ? .on : .off
        }
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
