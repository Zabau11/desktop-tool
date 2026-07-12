import AppKit

enum MarkerLayout {
    static let panelSize = CGSize(width: 96, height: 24)
    static let markerRect = CGRect(x: 12, y: 8, width: 72, height: 8)
    static let markerBottomInset: CGFloat = 12
}

enum MarkerPositioner {
    static func panelOrigin(
        screenFrame: CGRect,
        visibleFrame: CGRect,
        panelSize: CGSize = MarkerLayout.panelSize,
        markerRect: CGRect = MarkerLayout.markerRect,
        markerBottomInset: CGFloat = MarkerLayout.markerBottomInset
    ) -> CGPoint {
        let centeredX = screenFrame.midX - (panelSize.width / 2)
        let requestedY = visibleFrame.minY + markerBottomInset - markerRect.minY
        let maximumY = visibleFrame.maxY - panelSize.height
        let clampedY = max(visibleFrame.minY, min(requestedY, maximumY))

        return CGPoint(x: centeredX, y: clampedY)
    }
}
