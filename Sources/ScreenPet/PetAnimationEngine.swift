import Foundation

struct PetRenderState: Equatable {
    var eyeOpenness: CGFloat = 1
    var horizontalGaze: CGFloat = 0
    var mouthOpenness: CGFloat = 0
    var bodyScaleX: CGFloat = 1
    var bodyScaleY: CGFloat = 1

    static let neutral = PetRenderState()
}

/// A small, clock-independent animation state machine. The random source is
/// injected so timing and collision behavior can be tested deterministically.
final class PetAnimationEngine {
    typealias RandomSource = () -> Double

    private enum Behavior { case blink, glance, breathing, yawn }
    private struct Active {
        let behavior: Behavior
        let duration: TimeInterval
        let direction: CGFloat
        let repeats: Int
        var elapsed: TimeInterval = 0
    }

    private let random: RandomSource
    private let reduceMotion: Bool
    private var nextBlink: TimeInterval
    private var nextGlance: TimeInterval
    private var nextBreathing: TimeInterval
    private var nextYawn: TimeInterval
    private var active: Active?
    private var now: TimeInterval = 0

    private(set) var state = PetRenderState.neutral

    init(random: @escaping RandomSource = { Double.random(in: 0..<1) }, reduceMotion: Bool = false) {
        self.random = random
        self.reduceMotion = reduceMotion
        nextBlink = Self.interval(in: 4...9, random: random)
        nextGlance = Self.interval(in: 10...20, random: random)
        nextBreathing = Self.interval(in: 12...24, random: random)
        nextYawn = Self.interval(in: 35...70, random: random)
        if reduceMotion { nextBreathing = .infinity }
    }

    var isAnimating: Bool { active != nil }
    var timeUntilNextEvent: TimeInterval {
        max(0, [nextBlink, nextGlance, nextBreathing, nextYawn].min()! - now)
    }

    func reset() {
        now = 0
        active = nil
        state = .neutral
        nextBlink = Self.interval(in: 4...9, random: random)
        nextGlance = Self.interval(in: 10...20, random: random)
        nextBreathing = reduceMotion ? .infinity : Self.interval(in: 12...24, random: random)
        nextYawn = Self.interval(in: 35...70, random: random)
    }

    func advance(by delta: TimeInterval) {
        guard delta > 0 else { return }
        now += delta

        if var current = active {
            current.elapsed += delta
            active = current
            render(current)
            if current.elapsed >= current.duration {
                active = nil
                state = .neutral
                reschedule(current.behavior)
            }
            return
        }

        guard let behavior = dueBehavior() else { return }
        active = Active(
            behavior: behavior,
            duration: duration(for: behavior),
            direction: behavior == .glance ? (random() < 0.5 ? -1 : 1) : 0,
            repeats: behavior == .blink && random() < 0.15 ? 2 : 1
        )
        render(active!)
    }

    private func dueBehavior() -> Behavior? {
        let due: [(Behavior, TimeInterval)] = [
            (.yawn, nextYawn), (.blink, nextBlink), (.glance, nextGlance), (.breathing, nextBreathing)
        ]
        return due.first(where: { now >= $0.1 })?.0
    }

    private func duration(for behavior: Behavior) -> TimeInterval {
        switch behavior {
        case .blink: return 0.32
        case .glance: return Self.interval(in: 0.8...1.5, random: random)
        case .breathing: return 2.4
        case .yawn: return 1.8
        }
    }

    private func reschedule(_ behavior: Behavior) {
        switch behavior {
        case .blink: nextBlink = now + Self.interval(in: 4...9, random: random)
        case .glance: nextGlance = now + Self.interval(in: 10...20, random: random)
        case .breathing: nextBreathing = now + Self.interval(in: 12...24, random: random)
        case .yawn: nextYawn = now + Self.interval(in: 35...70, random: random)
        }
    }

    private func render(_ animation: Active) {
        let progress = min(1, animation.elapsed / animation.duration)
        switch animation.behavior {
        case .blink:
            let cycle = min(0.999, progress * CGFloat(animation.repeats))
            let cycleProgress = cycle - floor(cycle)
            let openness = cycleProgress < 0.5 ? 1 - cycleProgress * 2 : (cycleProgress - 0.5) * 2
            state = PetRenderState(eyeOpenness: openness, horizontalGaze: 0, mouthOpenness: 0, bodyScaleX: 1, bodyScaleY: 1)
        case .glance:
            let amount = progress < 0.5 ? progress * 2 : (1 - progress) * 2
            state = PetRenderState(eyeOpenness: 1, horizontalGaze: animation.direction * amount, mouthOpenness: 0, bodyScaleX: 1, bodyScaleY: 1)
        case .breathing:
            let amount = sin(progress * .pi)
            state = PetRenderState(eyeOpenness: 1, horizontalGaze: 0, mouthOpenness: 0, bodyScaleX: reduceMotion ? 1 : 1 + 0.025 * amount, bodyScaleY: reduceMotion ? 1 : 1 - 0.02 * amount)
        case .yawn:
            let amount = sin(progress * .pi)
            state = PetRenderState(eyeOpenness: 1 - 0.5 * amount, horizontalGaze: 0, mouthOpenness: 0.55 * amount, bodyScaleX: reduceMotion ? 1 : 1 + 0.025 * amount, bodyScaleY: reduceMotion ? 1 : 1 - 0.035 * amount)
        }
    }

    private static func interval(in range: ClosedRange<TimeInterval>, random: RandomSource) -> TimeInterval {
        range.lowerBound + (range.upperBound - range.lowerBound) * min(1, max(0, random()))
    }
}
