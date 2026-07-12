import AppKit
import Foundation

enum MarkerLayout {
    static let panelSize = CGSize(width: 96, height: 24)
    static let markerRect = CGRect(x: 12, y: 8, width: 72, height: 8)
    static let markerBottomInset: CGFloat = 12
    static let patrolDistance: CGFloat = 140
    static let patrolPeriod: TimeInterval = 8
}

enum MarkerMovement {
    static func horizontalOffset(
        elapsedTime: TimeInterval,
        distance: CGFloat = MarkerLayout.patrolDistance,
        period: TimeInterval = MarkerLayout.patrolPeriod
    ) -> CGFloat {
        guard period > 0 else { return 0 }

        let phase = (elapsedTime / period) * 2 * Double.pi
        return CGFloat(sin(phase)) * distance
    }
}

enum MarkerPositioner {
    static func panelOrigin(
        screenFrame: CGRect,
        visibleFrame: CGRect,
        panelSize: CGSize = MarkerLayout.panelSize,
        markerRect: CGRect = MarkerLayout.markerRect,
        markerBottomInset: CGFloat = MarkerLayout.markerBottomInset,
        horizontalOffset: CGFloat = 0
    ) -> CGPoint {
        let requestedX = screenFrame.midX - (panelSize.width / 2) + horizontalOffset
        let maximumX = visibleFrame.maxX - panelSize.width
        let clampedX = max(visibleFrame.minX, min(requestedX, maximumX))
        let requestedY = visibleFrame.minY + markerBottomInset - markerRect.minY
        let maximumY = visibleFrame.maxY - panelSize.height
        let clampedY = max(visibleFrame.minY, min(requestedY, maximumY))

        return CGPoint(x: clampedX, y: clampedY)
    }
}
