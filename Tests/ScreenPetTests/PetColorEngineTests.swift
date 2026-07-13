import Testing
@testable import ScreenPet

struct PetColorEngineTests {
    @Test
    func signalSelectsItsPaletteAndAnimatesTowardIt() {
        let engine = PetColorEngine(transitionDuration: 1)

        engine.setSignal(.focused)
        #expect(engine.signal == .focused)
        #expect(engine.isAnimating)
        #expect(engine.palette == SlimePalette.palette(for: .calm))

        engine.advance(by: 0.5)
        let midpoint = engine.palette
        #expect(midpoint != SlimePalette.palette(for: .calm))
        #expect(midpoint != SlimePalette.palette(for: .focused))

        engine.advance(by: 0.5)
        #expect(!engine.isAnimating)
        #expect(engine.palette == SlimePalette.palette(for: .focused))
    }

    @Test
    func changingSignalsMidTransitionContinuesFromTheCurrentColor() {
        let engine = PetColorEngine(transitionDuration: 1)
        engine.setSignal(.active)
        engine.advance(by: 0.4)
        let currentPalette = engine.palette

        engine.setSignal(.celebrating)
        #expect(engine.palette == currentPalette)

        engine.advance(by: 1)
        #expect(engine.palette == SlimePalette.palette(for: .celebrating))
    }

    @Test
    func reduceMotionAppliesSignalColorImmediately() {
        let engine = PetColorEngine(transitionDuration: 1, reduceMotion: true)

        engine.setSignal(.active)

        #expect(!engine.isAnimating)
        #expect(engine.palette == SlimePalette.palette(for: .active))
    }

    @Test
    func everySignalHasADistinctPalette() {
        let palettes = UserSignal.allCases.map(SlimePalette.palette(for:))
        #expect(Set(palettes.map { "\($0.gradientBottom.red),\($0.gradientBottom.green),\($0.gradientBottom.blue)" }).count == UserSignal.allCases.count)
    }
}
