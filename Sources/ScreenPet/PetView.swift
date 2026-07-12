import AppKit

final class PetView: NSView {
    private var animationState = PetAnimationState(
        horizontalOffset: 0,
        facingDirection: .right,
        bobOffset: 0,
        walkPhase: 0
    )
    private var diagnosticMessage: String?

    override var isOpaque: Bool { false }

    func setAnimationState(_ state: PetAnimationState) {
        animationState = state
        needsDisplay = true
    }

    func setDiagnosticMessage(_ message: String?) {
        diagnosticMessage = message
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let rect = PetLayout.petRect.offsetBy(dx: 0, dy: animationState.bobOffset)
        let isRight = animationState.facingDirection == .right
        let footOffset = sin(animationState.walkPhase) * PetLayout.footSwing

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }

        if let diagnosticMessage {
            let bubble = NSBezierPath(
                roundedRect: PetLayout.messageRect,
                xRadius: 8,
                yRadius: 8
            )
            NSColor(calibratedWhite: 1, alpha: 0.92).setFill()
            bubble.fill()
            NSColor(calibratedWhite: 0.15, alpha: 0.22).setStroke()
            bubble.lineWidth = 1
            bubble.stroke()

            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: NSColor(calibratedWhite: 0.12, alpha: 1)
            ]
            let text = NSAttributedString(string: diagnosticMessage, attributes: attributes)
            let textRect = PetLayout.messageRect.insetBy(dx: 8, dy: 2)
            text.draw(in: textRect)
        }

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
        shadow.shadowBlurRadius = 5
        shadow.shadowOffset = CGSize(width: 0, height: -2)
        shadow.set()

        let body = NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.32, yRadius: rect.height * 0.32)
        NSColor(calibratedRed: 0.98, green: 0.48, blue: 0.28, alpha: 1).setFill()
        body.fill()

        NSGraphicsContext.restoreGraphicsState()
        NSColor(calibratedWhite: 0.20, alpha: 0.9).setStroke()
        body.lineWidth = 1.5
        body.stroke()
        NSGraphicsContext.saveGraphicsState()

        let eyeY = rect.minY + rect.height * 0.62
        let nearEyeX = isRight ? rect.minX + rect.width * 0.61 : rect.minX + rect.width * 0.39
        let farEyeX = isRight ? rect.minX + rect.width * 0.39 : rect.minX + rect.width * 0.61
        for x in [farEyeX, nearEyeX] {
            let eye = NSBezierPath(ovalIn: CGRect(x: x - 4, y: eyeY - 4, width: 8, height: 8))
            NSColor.white.setFill()
            eye.fill()
            NSColor(calibratedWhite: 0.12, alpha: 1).setStroke()
            eye.lineWidth = 1
            eye.stroke()
            NSColor(calibratedWhite: 0.12, alpha: 1).setFill()
            NSBezierPath(ovalIn: CGRect(x: x - 1.5 + (isRight ? 0.7 : -0.7), y: eyeY - 1.5, width: 3, height: 3)).fill()
        }

        let footY = rect.minY - 1
        for (x, offset) in [(rect.minX + rect.width * 0.30, footOffset), (rect.minX + rect.width * 0.70, -footOffset)] {
            let foot = NSBezierPath(roundedRect: CGRect(x: x - 7, y: footY + offset, width: 14, height: 8), xRadius: 4, yRadius: 4)
            NSColor(calibratedRed: 0.83, green: 0.27, blue: 0.18, alpha: 1).setFill()
            foot.fill()
            NSColor(calibratedWhite: 0.20, alpha: 0.7).setStroke()
            foot.lineWidth = 1
            foot.stroke()
        }
    }
}
