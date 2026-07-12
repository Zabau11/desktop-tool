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

    @Test
    func appliesHorizontalPatrolOffset() {
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let visibleFrame = CGRect(x: 0, y: 0, width: 1440, height: 875)

        let origin = MarkerPositioner.panelOrigin(
            screenFrame: screenFrame,
            visibleFrame: visibleFrame,
            horizontalOffset: 90
        )

        #expect(origin.x == 762)
        #expect(origin.y == 4)
    }

    @Test
    func clampsMovementInsideUsableScreenBounds() {
        let screenFrame = CGRect(x: 0, y: 0, width: 300, height: 200)
        let visibleFrame = CGRect(x: 20, y: 0, width: 260, height: 175)

        let leftOrigin = MarkerPositioner.panelOrigin(
            screenFrame: screenFrame,
            visibleFrame: visibleFrame,
            horizontalOffset: -1_000
        )
        let rightOrigin = MarkerPositioner.panelOrigin(
            screenFrame: screenFrame,
            visibleFrame: visibleFrame,
            horizontalOffset: 1_000
        )

        #expect(leftOrigin.x == visibleFrame.minX)
        #expect(rightOrigin.x == visibleFrame.maxX - MarkerLayout.panelSize.width)
    }
}

struct MarkerMovementTests {
    @Test
    func followsSmoothPatrolCycle() {
        let period = MarkerLayout.patrolPeriod
        let distance = MarkerLayout.patrolDistance

        #expect(abs(MarkerMovement.horizontalOffset(elapsedTime: 0)) < 0.001)
        #expect(abs(MarkerMovement.horizontalOffset(elapsedTime: period / 4) - distance) < 0.001)
        #expect(abs(MarkerMovement.horizontalOffset(elapsedTime: period / 2)) < 0.001)
        #expect(abs(MarkerMovement.horizontalOffset(elapsedTime: period * 0.75) + distance) < 0.001)
        #expect(abs(MarkerMovement.horizontalOffset(elapsedTime: period)) < 0.001)
    }

    @Test
    func handlesInvalidPeriodWithoutProducingInvalidCoordinates() {
        #expect(MarkerMovement.horizontalOffset(elapsedTime: 2, period: 0) == 0)
    }
}
