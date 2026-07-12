import AppKit

@MainActor
final class OverlayWindowController {
    private let panel: NSPanel

    private(set) var isMarkerVisible = false

    init() {
        panel = NSPanel(
            contentRect: CGRect(origin: .zero, size: MarkerLayout.panelSize),
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
        panel.contentView = MarkerView(frame: CGRect(origin: .zero, size: MarkerLayout.panelSize))
    }

    func setMarkerVisible(_ visible: Bool) {
        isMarkerVisible = visible

        if visible {
            reposition()
            panel.orderFrontRegardless()
        } else {
            panel.orderOut(nil)
        }
    }

    func reposition() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        let origin = MarkerPositioner.panelOrigin(
            screenFrame: screen.frame,
            visibleFrame: screen.visibleFrame
        )
        panel.setFrameOrigin(origin)
    }
}
