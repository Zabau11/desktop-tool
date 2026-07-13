import Foundation

enum UserSignal: String, CaseIterable, Sendable {
    case calm
    case focused
    case active
    case celebrating

    var displayName: String {
        switch self {
        case .calm: return "Calm"
        case .focused: return "Focused"
        case .active: return "Active"
        case .celebrating: return "Celebrating"
        }
    }
}

struct SlimeColor: Equatable, Sendable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat = 1

    func interpolated(to other: SlimeColor, progress: CGFloat) -> SlimeColor {
        let amount = min(1, max(0, progress))
        return SlimeColor(
            red: red + (other.red - red) * amount,
            green: green + (other.green - green) * amount,
            blue: blue + (other.blue - blue) * amount,
            alpha: alpha + (other.alpha - alpha) * amount
        )
    }
}

struct SlimePalette: Equatable, Sendable {
    var shadowFill: SlimeColor
    var gradientTop: SlimeColor
    var gradientBottom: SlimeColor
    var outline: SlimeColor

    func interpolated(to other: SlimePalette, progress: CGFloat) -> SlimePalette {
        SlimePalette(
            shadowFill: shadowFill.interpolated(to: other.shadowFill, progress: progress),
            gradientTop: gradientTop.interpolated(to: other.gradientTop, progress: progress),
            gradientBottom: gradientBottom.interpolated(to: other.gradientBottom, progress: progress),
            outline: outline.interpolated(to: other.outline, progress: progress)
        )
    }

    static func palette(for signal: UserSignal) -> SlimePalette {
        switch signal {
        case .calm:
            return SlimePalette(
                shadowFill: SlimeColor(red: 0.35, green: 0.88, blue: 0.91, alpha: 0.96),
                gradientTop: SlimeColor(red: 0.82, green: 0.98, blue: 0.99, alpha: 0.98),
                gradientBottom: SlimeColor(red: 0.39, green: 0.86, blue: 0.90, alpha: 0.98),
                outline: SlimeColor(red: 0.12, green: 0.61, blue: 0.65, alpha: 0.95)
            )
        case .focused:
            return SlimePalette(
                shadowFill: SlimeColor(red: 0.49, green: 0.46, blue: 0.93, alpha: 0.96),
                gradientTop: SlimeColor(red: 0.88, green: 0.84, blue: 1.00, alpha: 0.98),
                gradientBottom: SlimeColor(red: 0.48, green: 0.42, blue: 0.91, alpha: 0.98),
                outline: SlimeColor(red: 0.29, green: 0.24, blue: 0.67, alpha: 0.95)
            )
        case .active:
            return SlimePalette(
                shadowFill: SlimeColor(red: 0.99, green: 0.53, blue: 0.36, alpha: 0.96),
                gradientTop: SlimeColor(red: 1.00, green: 0.88, blue: 0.68, alpha: 0.98),
                gradientBottom: SlimeColor(red: 0.98, green: 0.45, blue: 0.29, alpha: 0.98),
                outline: SlimeColor(red: 0.72, green: 0.25, blue: 0.16, alpha: 0.95)
            )
        case .celebrating:
            return SlimePalette(
                shadowFill: SlimeColor(red: 0.40, green: 0.86, blue: 0.49, alpha: 0.96),
                gradientTop: SlimeColor(red: 0.92, green: 1.00, blue: 0.66, alpha: 0.98),
                gradientBottom: SlimeColor(red: 0.31, green: 0.82, blue: 0.45, alpha: 0.98),
                outline: SlimeColor(red: 0.16, green: 0.58, blue: 0.29, alpha: 0.95)
            )
        }
    }
}

final class PetColorEngine {
    private let transitionDuration: TimeInterval
    private let reduceMotion: Bool
    private var elapsed: TimeInterval = 0
    private var startPalette: SlimePalette
    private var targetPalette: SlimePalette

    private(set) var signal: UserSignal
    private(set) var palette: SlimePalette
    private(set) var isAnimating = false

    init(
        initialSignal: UserSignal = .calm,
        transitionDuration: TimeInterval = 0.7,
        reduceMotion: Bool = false
    ) {
        signal = initialSignal
        palette = SlimePalette.palette(for: initialSignal)
        startPalette = palette
        targetPalette = palette
        self.transitionDuration = max(0, transitionDuration)
        self.reduceMotion = reduceMotion
    }

    func setSignal(_ newSignal: UserSignal) {
        guard newSignal != signal else { return }

        signal = newSignal
        startPalette = palette
        targetPalette = SlimePalette.palette(for: newSignal)
        elapsed = 0

        if reduceMotion || transitionDuration == 0 {
            palette = targetPalette
            isAnimating = false
        } else {
            isAnimating = true
        }
    }

    func advance(by delta: TimeInterval) {
        guard isAnimating, delta > 0 else { return }

        elapsed = min(transitionDuration, elapsed + delta)
        let linearProgress = CGFloat(elapsed / transitionDuration)
        let easedProgress = linearProgress * linearProgress * (3 - 2 * linearProgress)
        palette = startPalette.interpolated(to: targetPalette, progress: easedProgress)

        if elapsed >= transitionDuration {
            palette = targetPalette
            isAnimating = false
        }
    }
}
