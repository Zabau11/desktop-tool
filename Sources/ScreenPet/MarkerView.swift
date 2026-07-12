import AppKit

final class MarkerView: NSView {
    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let markerPath = NSBezierPath(
            roundedRect: MarkerLayout.markerRect,
            xRadius: MarkerLayout.markerRect.height / 2,
            yRadius: MarkerLayout.markerRect.height / 2
        )

        NSGraphicsContext.saveGraphicsState()

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.55)
        shadow.shadowBlurRadius = 4
        shadow.shadowOffset = CGSize(width: 0, height: -1)
        shadow.set()

        NSColor(
            calibratedRed: 1.0,
            green: 0.32,
            blue: 0.20,
            alpha: 1.0
        ).setFill()
        markerPath.fill()

        NSGraphicsContext.restoreGraphicsState()

        NSColor.black.withAlphaComponent(0.45).setStroke()
        markerPath.lineWidth = 1
        markerPath.stroke()
    }
}
