import AppKit

@MainActor
final class OverlayWindowController {
    private let panel: NSPanel
    private var movementTimer: Timer?
    private var movementStartedAt: TimeInterval?
    private var animationState = PetMovement.animationState(elapsedTime: 0)

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

        animationState = PetMovement.animationState(elapsedTime: 0)
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
        guard isPetVisible, let movementStartedAt else { return }

        let elapsedTime = ProcessInfo.processInfo.systemUptime - movementStartedAt
        animationState = PetMovement.animationState(
            elapsedTime: elapsedTime,
            previousFacingDirection: animationState.facingDirection
        )
        (panel.contentView as? PetView)?.setAnimationState(animationState)
        movePanel()
    }

    private func movePanel() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        let origin = PetPositioner.panelOrigin(
            screenFrame: screen.frame,
            visibleFrame: screen.visibleFrame,
            horizontalOffset: animationState.horizontalOffset
        )
        panel.setFrameOrigin(origin)
    }
}
