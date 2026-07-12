import CoreGraphics
import Testing
@testable import ScreenPet

struct MarkerPositionerTests {
    @Test
    func centersPanelAndKeepsMarkerTwelvePointsAboveUsableEdge() {
        let screenFrame = CGRect(x: 0, y: 0, width: 1728, height: 1117)
        let visibleFrame = CGRect(x: 0, y: 70, width: 1728, height: 1022)

        let origin = MarkerPositioner.panelOrigin(
            screenFrame: screenFrame,
            visibleFrame: visibleFrame
        )

        #expect(origin.x == 816)
        #expect(origin.y == 74)
        #expect(origin.y + MarkerLayout.markerRect.minY == visibleFrame.minY + 12)
    }

    @Test
    func usesPhysicalLowerEdgeWhenDockDoesNotConsumeBottomSpace() {
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let visibleFrame = CGRect(x: 0, y: 0, width: 1360, height: 875)

        let origin = MarkerPositioner.panelOrigin(
            screenFrame: screenFrame,
            visibleFrame: visibleFrame
        )

        #expect(origin.x == 672)
        #expect(origin.y == 4)
    }

    @Test
    func supportsScreensWithNegativeCoordinates() {
        let screenFrame = CGRect(x: -1920, y: -120, width: 1920, height: 1080)
        let visibleFrame = CGRect(x: -1920, y: -120, width: 1920, height: 1055)

        let origin = MarkerPositioner.panelOrigin(
            screenFrame: screenFrame,
            visibleFrame: visibleFrame
        )

        #expect(origin.x == -1008)
        #expect(origin.y == -116)
    }
}
