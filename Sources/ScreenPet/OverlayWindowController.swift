import AppKit

@MainActor
final class OverlayWindowController {
    private let panel: NSPanel
    private(set) var isPetVisible = false

    init() {
        panel = NSPanel(
            contentRect: CGRect(origin: .zero, size: PetLayout.panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.animationBehavior = .none
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary
        ]
        panel.contentView = PetView(frame: CGRect(origin: .zero, size: PetLayout.panelSize))
    }

    func setPetVisible(_ visible: Bool) {
        isPetVisible = visible

        if visible {
            reposition()
            panel.orderFrontRegardless()
            (panel.contentView as? PetView)?.startAnimations()
        } else {
            (panel.contentView as? PetView)?.stopAnimations()
            panel.orderOut(nil)
        }
    }

    func reposition() {
        movePanel()
    }

    private func movePanel() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        let origin = PetPositioner.panelOrigin(
            visibleFrame: screen.visibleFrame
        )
        panel.setFrameOrigin(origin)
    }
}
