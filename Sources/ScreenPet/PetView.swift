import AppKit

final class PetView: NSView {
    private let animationEngine = PetAnimationEngine(reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
    private let colorEngine = PetColorEngine(reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
    private var idleTimer: Timer?
    private var frameTimer: Timer?
    private var colorTimer: Timer?
    private var renderState = PetRenderState.neutral

    override var isOpaque: Bool { false }

    func startAnimations() {
        stopAnimations()
        animationEngine.reset()
        scheduleIdleTimer()
        scheduleColorTimerIfNeeded()
    }

    func stopAnimations() {
        idleTimer?.invalidate()
        frameTimer?.invalidate()
        colorTimer?.invalidate()
        idleTimer = nil
        frameTimer = nil
        colorTimer = nil
        animationEngine.reset()
        renderState = .neutral
        needsDisplay = true
    }

    func apply(signal: UserSignal) {
        colorEngine.setSignal(signal)
        needsDisplay = true

        scheduleColorTimerIfNeeded()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawSlime()
    }

    private func scheduleIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: max(0.01, animationEngine.timeUntilNextEvent), repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in self?.beginAnimationIfNeeded() }
        }
    }

    private func beginAnimationIfNeeded() {
        idleTimer = nil
        animationEngine.advance(by: 0.001)
        renderState = animationEngine.state
        needsDisplay = true
        guard animationEngine.isAnimating else { scheduleIdleTimer(); return }
        frameTimer?.invalidate()
        frameTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.advanceAnimationFrame() }
        }
    }

    private func advanceAnimationFrame() {
        animationEngine.advance(by: 1.0 / 30.0)
        renderState = animationEngine.state
        needsDisplay = true
        if !animationEngine.isAnimating {
            frameTimer?.invalidate()
            frameTimer = nil
            scheduleIdleTimer()
        }
    }

    private func scheduleColorTimerIfNeeded() {
        colorTimer?.invalidate()
        guard colorEngine.isAnimating else {
            colorTimer = nil
            return
        }

        colorTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.advanceColorFrame() }
        }
    }

    private func advanceColorFrame() {
        colorEngine.advance(by: 1.0 / 60.0)
        needsDisplay = true
        if !colorEngine.isAnimating {
            colorTimer?.invalidate()
            colorTimer = nil
        }
    }

    private func drawSlime() {
        let baseRect = PetLayout.petRect
        let rect = CGRect(
            x: baseRect.midX - baseRect.width * renderState.bodyScaleX / 2,
            y: baseRect.minY,
            width: baseRect.width * renderState.bodyScaleX,
            height: baseRect.height * renderState.bodyScaleY
        )
        let body = slimeBodyPath(in: rect)
        let palette = colorEngine.palette

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
        shadow.shadowBlurRadius = 5
        shadow.shadowOffset = CGSize(width: 0, height: -2)
        shadow.set()
        palette.shadowFill.nsColor.setFill()
        body.fill()
        NSGraphicsContext.restoreGraphicsState()

        let bodyGradient = NSGradient(colors: [
            palette.gradientTop.nsColor,
            palette.gradientBottom.nsColor
        ])
        bodyGradient?.draw(in: body, angle: -90)

        palette.outline.nsColor.setStroke()
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
        let gaze = renderState.horizontalGaze * rect.width * 0.07
        let eyeY = rect.minY + rect.height * 0.47
        let eyeWidth = rect.width * 0.13
        let eyeHeight = rect.height * 0.28

        for eyeX in [rect.minX + rect.width * 0.35, rect.minX + rect.width * 0.65] {
            let openness = renderState.eyeOpenness
            let eyeRect = CGRect(
                x: eyeX - eyeWidth / 2 + gaze,
                y: eyeY - max(eyeHeight * openness, 1) / 2,
                width: eyeWidth,
                height: max(eyeHeight * openness, 1)
            )
            NSColor(calibratedRed: 0.06, green: 0.10, blue: 0.19, alpha: 0.96).setFill()
            if openness < 0.12 {
                let eyelid = NSBezierPath()
                eyelid.move(to: CGPoint(x: eyeRect.minX, y: eyeY))
                eyelid.curve(to: CGPoint(x: eyeRect.maxX, y: eyeY), controlPoint1: CGPoint(x: eyeRect.minX + eyeRect.width * 0.35, y: eyeY - 1.5), controlPoint2: CGPoint(x: eyeRect.maxX - eyeRect.width * 0.35, y: eyeY - 1.5))
                eyelid.lineWidth = 1.6
                eyelid.lineCapStyle = .round
                eyelid.stroke()
            } else {
                NSBezierPath(ovalIn: eyeRect).fill()
            }

            let shine = NSBezierPath(ovalIn: CGRect(
                x: eyeRect.minX + eyeRect.width * 0.20,
                y: eyeRect.minY + eyeRect.height * 0.59,
                width: eyeRect.width * 0.29,
                height: eyeRect.width * 0.29
            ))
            NSColor.white.withAlphaComponent(0.95).setFill()
            shine.fill()
        }

        NSColor(calibratedRed: 0.06, green: 0.10, blue: 0.19, alpha: 0.9).setStroke()
        if renderState.mouthOpenness > 0.03 {
            NSBezierPath(ovalIn: CGRect(x: rect.midX - 3.5, y: rect.minY + rect.height * 0.32 - renderState.mouthOpenness * 3, width: 7, height: 3 + renderState.mouthOpenness * 10)).fill()
        } else {
            let mouth = NSBezierPath()
            mouth.move(to: CGPoint(x: rect.midX - 2.2, y: rect.minY + rect.height * 0.34))
            mouth.line(to: CGPoint(x: rect.midX + 2.2, y: rect.minY + rect.height * 0.34))
            mouth.lineWidth = 1.5
            mouth.lineCapStyle = .round
            mouth.stroke()
        }
    }
}

private extension SlimeColor {
    var nsColor: NSColor {
        NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
    }
}
