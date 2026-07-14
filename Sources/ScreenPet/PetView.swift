import AppKit

final class PetView: NSView {
    private let animationEngine = PetAnimationEngine(reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
    private let colorEngine = PetColorEngine(reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
    private let springEngine = SlimeSpringEngine(reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
    private var idleTimer: Timer?
    private var renderTimer: Timer?
    private var lastRenderTime: TimeInterval?
    private var renderState = PetRenderState.neutral

    override var isOpaque: Bool { false }

    func startAnimations() {
        stopAnimations()
        animationEngine.reset()
        springEngine.reset()
        scheduleIdleTimer()
    }

    func stopAnimations() {
        idleTimer?.invalidate()
        renderTimer?.invalidate()
        idleTimer = nil
        renderTimer = nil
        lastRenderTime = nil
        animationEngine.reset()
        springEngine.reset()
        renderState = .neutral
        needsDisplay = true
    }

    func apply(signal: UserSignal) {
        let changed = signal != colorEngine.signal
        colorEngine.setSignal(signal)
        if changed {
            springEngine.impulse(compression: 0.50)
        }
        needsDisplay = true
        scheduleRenderTimerIfNeeded()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawSlime()
    }

    private func scheduleIdleTimer() {
        idleTimer?.invalidate()
        let delay = max(0.01, animationEngine.timeUntilNextEvent)
        idleTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in self?.beginAnimationIfNeeded(after: delay) }
        }
    }

    private func beginAnimationIfNeeded(after idleDelay: TimeInterval) {
        idleTimer = nil
        animationEngine.advance(by: idleDelay)
        updateSpringTarget()
        needsDisplay = true
        scheduleRenderTimerIfNeeded()
    }

    private func scheduleRenderTimerIfNeeded() {
        guard renderTimer == nil,
              animationEngine.isAnimating || colorEngine.isAnimating || springEngine.isAnimating else { return }
        lastRenderTime = Date.timeIntervalSinceReferenceDate
        renderTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.advanceRenderFrame() }
        }
    }

    private func advanceRenderFrame() {
        let now = Date.timeIntervalSinceReferenceDate
        let delta = max(0, now - (lastRenderTime ?? now))
        lastRenderTime = now
        animationEngine.advance(by: delta)
        colorEngine.advance(by: delta)
        updateSpringTarget()
        springEngine.advance(by: delta)
        needsDisplay = true

        if !animationEngine.isAnimating && !colorEngine.isAnimating && !springEngine.isAnimating {
            renderTimer?.invalidate()
            renderTimer = nil
            lastRenderTime = nil
            scheduleIdleTimer()
        }
    }

    private func updateSpringTarget() {
        renderState = animationEngine.state
        springEngine.setTargets(
            squashTarget: renderState.squashTarget,
            leanTarget: renderState.leanTarget
        )
    }

    private func drawSlime() {
        let baseRect = PetLayout.petRect
        let geometry = SlimeShapeGeometry.calculate(in: baseRect, spring: springEngine.state)
        let body = slimeBodyPath(from: geometry)
        let palette = colorEngine.palette

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
        shadow.shadowBlurRadius = 5 + max(0, springEngine.state.compression) * 1.5
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

        drawBodyHighlights(in: geometry)
        drawFace(in: baseRect, spring: springEngine.state)
    }

    private func slimeBodyPath(from geometry: SlimeBezierGeometry) -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: geometry.bottomLeft)
        path.curve(to: geometry.leftShoulder, controlPoint1: geometry.controlPoints[0], controlPoint2: geometry.controlPoints[1])
        path.curve(to: geometry.apex, controlPoint1: geometry.controlPoints[2], controlPoint2: geometry.controlPoints[3])
        path.curve(to: geometry.rightShoulder, controlPoint1: geometry.controlPoints[4], controlPoint2: geometry.controlPoints[5])
        path.curve(to: geometry.bottomRight, controlPoint1: geometry.rightShoulder, controlPoint2: geometry.bottomRight)
        path.line(to: geometry.bottomLeft)
        path.close()
        return path
    }

    private func drawBodyHighlights(in geometry: SlimeBezierGeometry) {
        let upperHighlight = NSBezierPath()
        let upperStart = CGPoint(x: geometry.leftShoulder.x + (geometry.apex.x - geometry.leftShoulder.x) * 0.42, y: geometry.leftShoulder.y + (geometry.apex.y - geometry.leftShoulder.y) * 0.42)
        let upperEnd = CGPoint(x: geometry.leftShoulder.x + (geometry.apex.x - geometry.leftShoulder.x) * 0.68, y: geometry.leftShoulder.y + (geometry.apex.y - geometry.leftShoulder.y) * 0.68)
        upperHighlight.move(to: upperStart)
        upperHighlight.curve(to: upperEnd, controlPoint1: upperStart, controlPoint2: upperEnd)
        upperHighlight.lineWidth = 4
        upperHighlight.lineCapStyle = .round
        NSColor.white.withAlphaComponent(0.72).setStroke()
        upperHighlight.stroke()

        let lowerHighlight = NSBezierPath()
        lowerHighlight.move(to: geometry.bottomLeft)
        lowerHighlight.curve(to: CGPoint(x: geometry.bottomLeft.x + (geometry.bottomRight.x - geometry.bottomLeft.x) * 0.14, y: geometry.bottomLeft.y + 2), controlPoint1: geometry.bottomLeft, controlPoint2: geometry.bottomLeft)
        lowerHighlight.lineWidth = 2
        lowerHighlight.lineCapStyle = .round
        NSColor.white.withAlphaComponent(0.46).setStroke()
        lowerHighlight.stroke()
    }

    private func drawFace(in baseRect: CGRect, spring: SlimeSpringState) {
        let faceRect = baseRect.offsetBy(dx: spring.lean * 1.6, dy: spring.lean * 0.8)
        let gaze = renderState.horizontalGaze * faceRect.width * 0.07
        let eyeY = faceRect.minY + faceRect.height * 0.47
        let eyeWidth = faceRect.width * 0.13
        let eyeHeight = faceRect.height * 0.28

        for eyeX in [faceRect.minX + faceRect.width * 0.35, faceRect.minX + faceRect.width * 0.65] {
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
            NSBezierPath(ovalIn: CGRect(x: faceRect.midX - 3.5, y: faceRect.minY + faceRect.height * 0.32 - renderState.mouthOpenness * 3, width: 7, height: 3 + renderState.mouthOpenness * 10)).fill()
        } else {
            let mouth = NSBezierPath()
            mouth.move(to: CGPoint(x: faceRect.midX - 2.2, y: faceRect.minY + faceRect.height * 0.34))
            mouth.line(to: CGPoint(x: faceRect.midX + 2.2, y: faceRect.minY + faceRect.height * 0.34))
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
