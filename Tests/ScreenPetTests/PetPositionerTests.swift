import CoreGraphics
import Testing
@testable import ScreenPet

struct PetPositionerTests {
    @Test
    func centersPanelAndKeepsPetAboveUsableEdge() {
        let screenFrame = CGRect(x: 0, y: 0, width: 1728, height: 1117)
        let visibleFrame = CGRect(x: 0, y: 70, width: 1728, height: 1022)
        let origin = PetPositioner.panelOrigin(screenFrame: screenFrame, visibleFrame: visibleFrame)

        #expect(origin.x == 779)
        #expect(origin.y == 70)
        #expect(origin.y + PetLayout.petRect.minY == visibleFrame.minY + PetLayout.petBottomInset)
    }

    @Test
    func supportsSmallAndNegativelyPositionedScreens() {
        let smallScreen = CGRect(x: 0, y: 0, width: 300, height: 200)
        let smallVisible = CGRect(x: 20, y: 0, width: 260, height: 175)
        let left = PetPositioner.panelOrigin(screenFrame: smallScreen, visibleFrame: smallVisible, horizontalOffset: -1_000)
        let right = PetPositioner.panelOrigin(screenFrame: smallScreen, visibleFrame: smallVisible, horizontalOffset: 1_000)
        #expect(left.x == smallVisible.minX)
        #expect(right.x == smallVisible.maxX - PetLayout.panelSize.width)

        let negativeScreen = CGRect(x: -1920, y: -120, width: 1920, height: 1080)
        let negativeVisible = CGRect(x: -1920, y: -120, width: 1920, height: 1055)
        let origin = PetPositioner.panelOrigin(screenFrame: negativeScreen, visibleFrame: negativeVisible)
        #expect(origin.x == -1045)
        #expect(origin.y == -120)
    }

    @Test
    func appliesHorizontalPatrolOffset() {
        let frame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let visible = CGRect(x: 0, y: 0, width: 1440, height: 875)
        let origin = PetPositioner.panelOrigin(screenFrame: frame, visibleFrame: visible, horizontalOffset: 90)
        #expect(origin.x == 725)
        #expect(origin.y == 0)
    }
}

struct PetMovementTests {
    @Test
    func followsSmoothPatrolCycle() {
        let period = PetLayout.patrolPeriod
        let distance = PetLayout.patrolDistance
        #expect(abs(PetMovement.horizontalOffset(elapsedTime: 0)) < 0.001)
        #expect(abs(PetMovement.horizontalOffset(elapsedTime: period / 4) - distance) < 0.001)
        #expect(abs(PetMovement.horizontalOffset(elapsedTime: period / 2)) < 0.001)
        #expect(abs(PetMovement.horizontalOffset(elapsedTime: period * 0.75) + distance) < 0.001)
        #expect(abs(PetMovement.horizontalOffset(elapsedTime: period)) < 0.001)
    }

    @Test
    func facesTravelDirectionAndRetainsItAtTurningPoints() {
        let period = PetLayout.patrolPeriod
        #expect(PetMovement.animationState(elapsedTime: 0).facingDirection == .right)
        #expect(PetMovement.animationState(elapsedTime: period * 0.25).facingDirection == .right)
        #expect(PetMovement.animationState(elapsedTime: period * 0.5).facingDirection == .left)
        #expect(PetMovement.animationState(elapsedTime: period * 0.75, previousFacingDirection: .left).facingDirection == .left)
        #expect(PetMovement.animationState(elapsedTime: period * 0.5, previousFacingDirection: .right).facingDirection == .left)
    }

    @Test
    func animationDetailsStayWithinLayoutBounds() {
        for step in 0..<120 {
            let state = PetMovement.animationState(elapsedTime: Double(step) / 30)
            #expect(abs(state.bobOffset) <= PetLayout.bobAmplitude)
            #expect(state.walkPhase >= 0)
            #expect(state.walkPhase < 2 * .pi)
        }
    }

    @Test
    func handlesInvalidPeriodWithoutInvalidCoordinates() {
        #expect(PetMovement.horizontalOffset(elapsedTime: 2, period: 0) == 0)
    }
}
