import CoreGraphics
import Testing
@testable import ScreenPet

struct PetPositionerTests {
    @Test
    func anchorsPanelAtBottomRightOfUsableScreen() {
        let visibleFrame = CGRect(x: 0, y: 70, width: 1728, height: 1022)
        let origin = PetPositioner.panelOrigin(visibleFrame: visibleFrame)

        #expect(origin.x == 1612)
        #expect(origin.y == 70)
        #expect(origin.y + PetLayout.petRect.minY == visibleFrame.minY + PetLayout.petBottomInset)
        #expect(origin.x + PetLayout.petRect.maxX == visibleFrame.maxX - PetLayout.petBottomInset)
    }

    @Test
    func supportsSmallAndNegativelyPositionedScreens() {
        let smallVisible = CGRect(x: 20, y: 0, width: 260, height: 175)
        let smallOrigin = PetPositioner.panelOrigin(visibleFrame: smallVisible)
        #expect(smallOrigin.x == smallVisible.maxX - PetLayout.panelSize.width)

        let negativeVisible = CGRect(x: -1920, y: -120, width: 1920, height: 1055)
        let origin = PetPositioner.panelOrigin(visibleFrame: negativeVisible)
        #expect(origin.x == -116)
        #expect(origin.y == -120)
    }

    @Test
    func keepsPanelOnScreenWhenUsableAreaIsNarrowerThanPanel() {
        let visible = CGRect(x: 20, y: 0, width: 120, height: 175)
        let origin = PetPositioner.panelOrigin(visibleFrame: visible)
        #expect(origin.x == visible.maxX - PetLayout.panelSize.width)
        #expect(origin.y == 0)
    }
}
