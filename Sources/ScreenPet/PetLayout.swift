import AppKit

enum PetLayout {
    static let panelSize = CGSize(width: 116, height: 69)
    static let petRect = CGRect(x: 10, y: 10, width: 96, height: 49)
    static let petBottomInset: CGFloat = 10
}

enum PetPositioner {
    static func panelOrigin(
        visibleFrame: CGRect,
        panelSize: CGSize = PetLayout.panelSize,
        petRect: CGRect = PetLayout.petRect,
        petBottomInset: CGFloat = PetLayout.petBottomInset
    ) -> CGPoint {
        let requestedX = visibleFrame.maxX - panelSize.width
        let clampedX = max(visibleFrame.minX, requestedX)
        let requestedY = visibleFrame.minY + petBottomInset - petRect.minY
        let maximumY = visibleFrame.maxY - panelSize.height
        let clampedY = max(visibleFrame.minY, min(requestedY, maximumY))

        return CGPoint(x: clampedX, y: clampedY)
    }
}
