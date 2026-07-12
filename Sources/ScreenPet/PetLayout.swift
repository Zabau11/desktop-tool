import AppKit
import Foundation

enum PetFacingDirection: Equatable {
    case left
    case right
}

struct PetAnimationState: Equatable {
    let horizontalOffset: CGFloat
    let facingDirection: PetFacingDirection
    let bobOffset: CGFloat
    let walkPhase: CGFloat
}

enum PetLayout {
    static let panelSize = CGSize(width: 170, height: 86)
    static let petRect = CGRect(x: 43, y: 10, width: 84, height: 44)
    static let messageRect = CGRect(x: 8, y: 61, width: 154, height: 20)
    static let petBottomInset: CGFloat = 10
    static let patrolDistance: CGFloat = 140
    static let patrolPeriod: TimeInterval = 8

    static let bobAmplitude: CGFloat = 1.5
    static let walkCyclePeriod: TimeInterval = 0.72
    static let footSwing: CGFloat = 1.5
    static let directionVelocityThreshold: CGFloat = 0.01
    static let messageDisplayDuration: TimeInterval = 1.2
}

enum PetMovement {
    static func animationState(
        elapsedTime: TimeInterval,
        previousFacingDirection: PetFacingDirection = .right,
        distance: CGFloat = PetLayout.patrolDistance,
        period: TimeInterval = PetLayout.patrolPeriod
    ) -> PetAnimationState {
        let horizontalOffset = self.horizontalOffset(
            elapsedTime: elapsedTime,
            distance: distance,
            period: period
        )

        let patrolPhase = period > 0
            ? (elapsedTime / period) * 2 * Double.pi
            : 0
        let velocity = distance * CGFloat(2 * Double.pi / max(period, 1)) * CGFloat(cos(patrolPhase))
        let facingDirection: PetFacingDirection
        if abs(velocity) <= PetLayout.directionVelocityThreshold {
            facingDirection = previousFacingDirection
        } else {
            facingDirection = velocity > 0 ? .right : .left
        }

        let walkPhase = normalizedPhase(elapsedTime: elapsedTime, period: PetLayout.walkCyclePeriod)
        let bobOffset = sin(walkPhase) * PetLayout.bobAmplitude

        return PetAnimationState(
            horizontalOffset: horizontalOffset,
            facingDirection: facingDirection,
            bobOffset: bobOffset,
            walkPhase: walkPhase
        )
    }

    static func horizontalOffset(
        elapsedTime: TimeInterval,
        distance: CGFloat = PetLayout.patrolDistance,
        period: TimeInterval = PetLayout.patrolPeriod
    ) -> CGFloat {
        guard period > 0 else { return 0 }

        let phase = (elapsedTime / period) * 2 * Double.pi
        return CGFloat(sin(phase)) * distance
    }

    private static func normalizedPhase(elapsedTime: TimeInterval, period: TimeInterval) -> CGFloat {
        guard period > 0 else { return 0 }

        let phase = (elapsedTime / period) * 2 * Double.pi
        return CGFloat(phase.truncatingRemainder(dividingBy: 2 * Double.pi))
    }
}

enum PetPositioner {
    static func panelOrigin(
        screenFrame: CGRect,
        visibleFrame: CGRect,
        panelSize: CGSize = PetLayout.panelSize,
        petRect: CGRect = PetLayout.petRect,
        petBottomInset: CGFloat = PetLayout.petBottomInset,
        horizontalOffset: CGFloat = 0
    ) -> CGPoint {
        let requestedX = screenFrame.midX - (panelSize.width / 2) + horizontalOffset
        let maximumX = visibleFrame.maxX - panelSize.width
        let clampedX = max(visibleFrame.minX, min(requestedX, maximumX))
        let requestedY = visibleFrame.minY + petBottomInset - petRect.minY
        let maximumY = visibleFrame.maxY - panelSize.height
        let clampedY = max(visibleFrame.minY, min(requestedY, maximumY))

        return CGPoint(x: clampedX, y: clampedY)
    }
}
