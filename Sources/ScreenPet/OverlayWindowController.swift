import AppKit

@MainActor
final class OverlayWindowController {
    private let panel: NSPanel
    private var movementTimer: Timer?
    private var movementStartedAt: TimeInterval?
    private var horizontalOffset: CGFloat = 0

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
            startMovement()
            reposition()
            panel.orderFrontRegardless()
        } else {
            stopMovement()
            panel.orderOut(nil)
        }
    }

    func reposition() {
        movePanel()
    }

    private func startMovement() {
        guard movementTimer == nil else { return }

        horizontalOffset = 0
        movementStartedAt = ProcessInfo.processInfo.systemUptime

        let timer = Timer(
            timeInterval: 1.0 / 30.0,
            target: self,
            selector: #selector(advanceMovement(_:)),
            userInfo: nil,
            repeats: true
        )
        timer.tolerance = 1.0 / 120.0
        movementTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopMovement() {
        movementTimer?.invalidate()
        movementTimer = nil
        movementStartedAt = nil
    }

    @objc
    private func advanceMovement(_ timer: Timer) {
        guard isMarkerVisible, let movementStartedAt else { return }

        let elapsedTime = ProcessInfo.processInfo.systemUptime - movementStartedAt
        horizontalOffset = MarkerMovement.horizontalOffset(elapsedTime: elapsedTime)
        movePanel()
    }

    private func movePanel() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        let origin = MarkerPositioner.panelOrigin(
            screenFrame: screen.frame,
            visibleFrame: screen.visibleFrame,
            horizontalOffset: horizontalOffset
        )
        panel.setFrameOrigin(origin)
    }
}
