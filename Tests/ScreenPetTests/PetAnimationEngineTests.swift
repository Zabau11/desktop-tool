import Testing
@testable import ScreenPet

struct PetAnimationEngineTests {
    @Test
    func startsBlinkAtTheScheduledTimeAndReturnsToNeutral() {
        var calls = 0
        let engine = PetAnimationEngine(random: {
            defer { calls += 1 }
            return calls < 4 ? 0 : 0.99
        })
        engine.advance(by: 4)
        #expect(engine.isAnimating)
        #expect(engine.state.eyeOpenness == 1)
        engine.advance(by: 0.16)
        #expect(engine.state.eyeOpenness == 0)
        engine.advance(by: 0.16)
        #expect(engine.state == .neutral)
    }

    @Test
    func reduceMotionKeepsBodyAtNeutralScale() {
        let engine = PetAnimationEngine(random: { 0 }, reduceMotion: true)
        engine.advance(by: 35)
        engine.advance(by: 0.9)
        #expect(engine.state.squashTarget == 0)
        #expect(engine.state.leanTarget == 0)
        #expect(engine.state.mouthOpenness > 0)
    }

    @Test
    func valuesStayWithinNormalizedBounds() {
        let engine = PetAnimationEngine(random: { 0 })
        for _ in 0..<200 {
            engine.advance(by: 0.5)
            #expect((0...1).contains(engine.state.eyeOpenness))
            #expect((-1...1).contains(engine.state.horizontalGaze))
            #expect((0...1).contains(engine.state.mouthOpenness))
            #expect((-1...1).contains(engine.state.squashTarget))
            #expect((-1...1).contains(engine.state.leanTarget))
        }
    }

    @Test
    func yawnWinsWhenAllBehaviorsAreDue() {
        let engine = PetAnimationEngine(random: { 0 })
        engine.advance(by: 35)
        #expect(engine.state.mouthOpenness == 0)
        engine.advance(by: 0.9)
        #expect(engine.state.mouthOpenness > 0)
        #expect(engine.state.eyeOpenness < 1)
        #expect(engine.state.squashTarget > 0)
    }

    @Test
    func deferredEventsAreRescheduledAfterAnActiveAnimation() {
        let engine = PetAnimationEngine(random: { 0 })
        engine.advance(by: 35)
        engine.advance(by: 1.8)
        #expect(!engine.isAnimating)
        #expect(engine.timeUntilNextEvent >= 4)
    }
}
