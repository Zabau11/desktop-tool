import Foundation

struct SlimeSpringState: Equatable {
    var compression: CGFloat = 0
    var lean: CGFloat = 0
    var compressionVelocity: CGFloat = 0
    var leanVelocity: CGFloat = 0

    static let neutral = SlimeSpringState()
    var isSettled: Bool {
        abs(compression) < 0.001 && abs(lean) < 0.001 &&
            abs(compressionVelocity) < 0.001 && abs(leanVelocity) < 0.001
    }
}

/// A deterministic spring solver. The fixed substep keeps the result stable
/// regardless of display-link frame gaps.
final class SlimeSpringEngine {
    static let stiffness: CGFloat = 145
    static let damping: CGFloat = 18
    static let fixedStep: TimeInterval = 1.0 / 120.0
    static let settlingThreshold: CGFloat = 0.001

    private let reduceMotion: Bool
    private(set) var state = SlimeSpringState.neutral
    private var squashTarget: CGFloat = 0
    private var leanTarget: CGFloat = 0

    init(reduceMotion: Bool = false) {
        self.reduceMotion = reduceMotion
    }

    var isAnimating: Bool {
        guard !reduceMotion else { return false }
        return !state.isSettled || abs(squashTarget) >= Self.settlingThreshold || abs(leanTarget) >= Self.settlingThreshold
    }

    func setTargets(squashTarget: CGFloat, leanTarget: CGFloat) {
        guard !reduceMotion else {
            self.squashTarget = 0
            self.leanTarget = 0
            state = .neutral
            return
        }
        self.squashTarget = clamp(squashTarget, -1, 1)
        self.leanTarget = clamp(leanTarget, -1, 1)
    }

    func impulse(compression: CGFloat) {
        guard !reduceMotion else { return }
        state.compressionVelocity += clamp(compression, -1, 1)
    }

    func advance(by delta: TimeInterval) {
        guard !reduceMotion, delta > 0 else {
            if reduceMotion { state = .neutral }
            return
        }

        var remaining = delta
        while remaining > 0 {
            let step = min(Self.fixedStep, remaining)
            integrate(step: step)
            remaining -= step
        }

        if abs(state.compression) < Self.settlingThreshold &&
            abs(state.compressionVelocity) < Self.settlingThreshold &&
            abs(squashTarget) < Self.settlingThreshold {
            state.compression = 0
            state.compressionVelocity = 0
        }
        if abs(state.lean) < Self.settlingThreshold &&
            abs(state.leanVelocity) < Self.settlingThreshold &&
            abs(leanTarget) < Self.settlingThreshold {
            state.lean = 0
            state.leanVelocity = 0
        }
    }

    func reset() {
        state = .neutral
        squashTarget = 0
        leanTarget = 0
    }

    private func integrate(step: TimeInterval) {
        let dt = CGFloat(step)
        state.compressionVelocity += (Self.stiffness * (squashTarget - state.compression) - Self.damping * state.compressionVelocity) * dt
        state.leanVelocity += (Self.stiffness * (leanTarget - state.lean) - Self.damping * state.leanVelocity) * dt
        state.compression += state.compressionVelocity * dt
        state.lean += state.leanVelocity * dt
        state.compression = clamp(state.compression, -1.2, 1.2)
        state.lean = clamp(state.lean, -1.2, 1.2)
    }

    private func clamp(_ value: CGFloat, _ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
        min(upper, max(lower, value))
    }
}

struct SlimeBezierGeometry: Equatable {
    var bottomLeft: CGPoint
    var leftShoulder: CGPoint
    var apex: CGPoint
    var rightShoulder: CGPoint
    var bottomRight: CGPoint
    var controlPoints: [CGPoint]

    var allPoints: [CGPoint] {
        [bottomLeft, leftShoulder, apex, rightShoulder, bottomRight] + controlPoints
    }
}

enum SlimeShapeGeometry {
    static let maxWidthExpansion: CGFloat = 0.06
    static let maxHeightReduction: CGFloat = 0.07
    static let maxApexShift: CGFloat = 3

    static func calculate(in baseRect: CGRect, spring: SlimeSpringState) -> SlimeBezierGeometry {
        let compression = clamp(spring.compression, -1, 1)
        let lean = clamp(spring.lean, -1, 1)
        let width = baseRect.width * clamp(1 + compression * maxWidthExpansion, 1 - maxWidthExpansion, 1 + maxWidthExpansion)
        let height = baseRect.height * clamp(1 - compression * maxHeightReduction, 1 - maxHeightReduction, 1 + maxHeightReduction)
        let center = baseRect.midX
        let left = center - width / 2
        let right = center + width / 2
        let bottom = baseRect.minY
        let top = bottom + height
        let apex = CGPoint(x: center + lean * 2, y: top + lean * maxApexShift)
        let wobble = clamp(spring.leanVelocity * 0.9, -2, 2)
        let leftShoulder = CGPoint(x: left, y: bottom + height * 0.50 + wobble)
        let rightShoulder = CGPoint(x: right, y: bottom + height * 0.50 - wobble)

        return SlimeBezierGeometry(
            bottomLeft: CGPoint(x: left + width * 0.08, y: bottom),
            leftShoulder: leftShoulder,
            apex: apex,
            rightShoulder: rightShoulder,
            bottomRight: CGPoint(x: right - width * 0.08, y: bottom),
            controlPoints: [
                CGPoint(x: left, y: bottom + height * 0.16),
                CGPoint(x: left + width * 0.05, y: bottom + height * 0.38 + wobble),
                CGPoint(x: left + width * 0.24, y: top),
                CGPoint(x: right - width * 0.24, y: top),
                CGPoint(x: right - width * 0.05, y: bottom + height * 0.38 - wobble),
                CGPoint(x: right, y: bottom + height * 0.16)
            ]
        )
    }

    private static func clamp(_ value: CGFloat, _ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
        min(upper, max(lower, value))
    }
}
