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

        if let diagnosticMessage {
            drawDiagnosticMessage(diagnosticMessage)
        }

        drawSlime()
    }

    private func drawSlime() {
        let compression = abs(sin(animationState.walkPhase))
        var rect = PetLayout.petRect.offsetBy(dx: 0, dy: animationState.bobOffset)
        rect = rect.insetBy(dx: -compression * 1.2, dy: compression * 0.8)
        rect.origin.y -= compression * 0.8

        let body = slimeBodyPath(in: rect)

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
        shadow.shadowBlurRadius = 5
        shadow.shadowOffset = CGSize(width: 0, height: -2)
        shadow.set()
        NSColor(calibratedRed: 0.35, green: 0.88, blue: 0.91, alpha: 0.96).setFill()
        body.fill()
        NSGraphicsContext.restoreGraphicsState()

        let bodyGradient = NSGradient(colors: [
            NSColor(calibratedRed: 0.82, green: 0.98, blue: 0.99, alpha: 0.98),
            NSColor(calibratedRed: 0.39, green: 0.86, blue: 0.90, alpha: 0.98)
        ])
        bodyGradient?.draw(in: body, angle: -90)

        NSColor(calibratedRed: 0.12, green: 0.61, blue: 0.65, alpha: 0.95).setStroke()
        body.lineWidth = 2
        body.stroke()

        drawBodyHighlights(in: rect)
        drawFace(in: rect)
    }

    private func slimeBodyPath(in rect: CGRect) -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.08))
        path.curve(
            to: CGPoint(x: rect.minX + rect.width * 0.03, y: rect.minY + rect.height * 0.34),
            controlPoint1: CGPoint(x: rect.minX + rect.width * 0.03, y: rect.minY + rect.height * 0.11),
            controlPoint2: CGPoint(x: rect.minX + rect.width * 0.02, y: rect.minY + rect.height * 0.22)
        )
        path.curve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            controlPoint1: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.76),
            controlPoint2: CGPoint(x: rect.minX + rect.width * 0.26, y: rect.maxY)
        )
        path.curve(
            to: CGPoint(x: rect.maxX - rect.width * 0.03, y: rect.minY + rect.height * 0.34),
            controlPoint1: CGPoint(x: rect.maxX - rect.width * 0.26, y: rect.maxY),
            controlPoint2: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.minY + rect.height * 0.76)
        )
        path.curve(
            to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.minY + rect.height * 0.08),
            controlPoint1: CGPoint(x: rect.maxX - rect.width * 0.02, y: rect.minY + rect.height * 0.22),
            controlPoint2: CGPoint(x: rect.maxX - rect.width * 0.03, y: rect.minY + rect.height * 0.11)
        )
        path.curve(
            to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.08),
            controlPoint1: CGPoint(x: rect.maxX - rect.width * 0.24, y: rect.minY),
            controlPoint2: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.minY)
        )
        path.close()
        return path
    }

    private func drawBodyHighlights(in rect: CGRect) {
        let upperHighlight = NSBezierPath()
        upperHighlight.move(to: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.minY + rect.height * 0.77))
        upperHighlight.curve(
            to: CGPoint(x: rect.minX + rect.width * 0.37, y: rect.minY + rect.height * 0.91),
            controlPoint1: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.minY + rect.height * 0.87),
            controlPoint2: CGPoint(x: rect.minX + rect.width * 0.31, y: rect.minY + rect.height * 0.91)
        )
        upperHighlight.lineWidth = 4
        upperHighlight.lineCapStyle = .round
        NSColor.white.withAlphaComponent(0.72).setStroke()
        upperHighlight.stroke()

        let lowerHighlight = NSBezierPath()
        lowerHighlight.move(to: CGPoint(x: rect.minX + rect.width * 0.11, y: rect.minY + rect.height * 0.14))
        lowerHighlight.curve(
            to: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.minY + rect.height * 0.10),
            controlPoint1: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.minY + rect.height * 0.10),
            controlPoint2: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.09)
        )
        lowerHighlight.lineWidth = 2
        lowerHighlight.lineCapStyle = .round
        NSColor.white.withAlphaComponent(0.46).setStroke()
        lowerHighlight.stroke()
    }

    private func drawFace(in rect: CGRect) {
        let gaze: CGFloat = animationState.facingDirection == .right ? 0.8 : -0.8
        let eyeY = rect.minY + rect.height * 0.47
        let eyeWidth = rect.width * 0.13
        let eyeHeight = rect.height * 0.28

        for eyeX in [rect.minX + rect.width * 0.35, rect.minX + rect.width * 0.65] {
            let eyeRect = CGRect(
                x: eyeX - eyeWidth / 2 + gaze,
                y: eyeY - eyeHeight / 2,
                width: eyeWidth,
                height: eyeHeight
            )
            let eye = NSBezierPath(ovalIn: eyeRect)
            NSColor(calibratedRed: 0.06, green: 0.10, blue: 0.19, alpha: 0.96).setFill()
            eye.fill()

            let shine = NSBezierPath(ovalIn: CGRect(
                x: eyeRect.minX + eyeRect.width * 0.20,
                y: eyeRect.minY + eyeRect.height * 0.59,
                width: eyeRect.width * 0.29,
                height: eyeRect.width * 0.29
            ))
            NSColor.white.withAlphaComponent(0.95).setFill()
            shine.fill()
        }

        let mouth = NSBezierPath()
        mouth.move(to: CGPoint(x: rect.midX - 2.2 + gaze * 0.25, y: rect.minY + rect.height * 0.34))
        mouth.line(to: CGPoint(x: rect.midX + 2.2 + gaze * 0.25, y: rect.minY + rect.height * 0.34))
        mouth.lineWidth = 1.5
        mouth.lineCapStyle = .round
        NSColor(calibratedRed: 0.06, green: 0.10, blue: 0.19, alpha: 0.9).setStroke()
        mouth.stroke()
    }

    private func drawDiagnosticMessage(_ message: String) {
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
        let text = NSAttributedString(string: message, attributes: attributes)
        text.draw(in: PetLayout.messageRect.insetBy(dx: 8, dy: 2))
    }
}
