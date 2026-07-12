import Testing
@testable import ScreenPet

struct InputEventClassifierTests {
    @Test
    func classifiesEveryMouseDownAsAClick() {
        #expect(InputEventClassifier.message(for: .mouseDown) == "Click detected")
    }

    @Test
    func classifiesSpaceKeyDown() {
        #expect(InputEventClassifier.message(for: .keyDown(keyCode: 49, isRepeat: false)) == "Space pressed")
    }

    @Test
    func ignoresRepeatedSpaceKeyDown() {
        #expect(InputEventClassifier.message(for: .keyDown(keyCode: 49, isRepeat: true)) == nil)
    }

    @Test
    func ignoresOtherKeysAndEvents() {
        #expect(InputEventClassifier.message(for: .keyDown(keyCode: 36, isRepeat: false)) == nil)
        #expect(InputEventClassifier.message(for: .other) == nil)
    }
}
