import CoreGraphics
import Testing
@testable import ScreenPet

struct SlimeSpringEngineTests {
    @Test
    func springOvershootsOnceAndSettlesDeterministically() {
        let first = SlimeSpringEngine()
        let second = SlimeSpringEngine()
        first.setTargets(squashTarget: 0.32, leanTarget: 0)
        second.setTargets(squashTarget: 0.32, leanTarget: 0)

        var maximum: CGFloat = 0
        for _ in 0..<240 {
            first.advance(by: SlimeSpringEngine.fixedStep)
            second.advance(by: SlimeSpringEngine.fixedStep)
            maximum = max(maximum, first.state.compression)
            #expect(first.state == second.state)
        }
        #expect(maximum > 0.32)

        first.setTargets(squashTarget: 0, leanTarget: 0)
        for _ in 0..<2400 { first.advance(by: SlimeSpringEngine.fixedStep) }
        #expect(first.state.isSettled)
    }

    @Test
    func largeFrameGapsRemainStableAndBounded() {
        let engine = SlimeSpringEngine()
        engine.setTargets(squashTarget: 1, leanTarget: 1)
        engine.advance(by: 10)
        #expect(abs(engine.state.compression) <= 1.2)
        #expect(abs(engine.state.lean) <= 1.2)
        #expect(engine.state.compression.isFinite)
        #expect(engine.state.lean.isFinite)
    }

    @Test
    func reduceMotionAlwaysReturnsNeutralDeformation() {
        let engine = SlimeSpringEngine(reduceMotion: true)
        engine.setTargets(squashTarget: 0.5, leanTarget: 0.5)
        engine.impulse(compression: 0.5)
        engine.advance(by: 1)
        #expect(engine.state == .neutral)
        #expect(!engine.isAnimating)
    }

    @Test
    func geometryKeepsBaseFixedAndStaysInsidePanel() {
        let panel = CGRect(x: 0, y: 0, width: 116, height: 69)
        let base = CGRect(x: 10, y: 10, width: 96, height: 49)
        let geometry = SlimeShapeGeometry.calculate(
            in: base,
            spring: SlimeSpringState(compression: 1, lean: 1, compressionVelocity: 2, leanVelocity: 2)
        )

        #expect(geometry.bottomLeft.y == base.minY)
        #expect(geometry.bottomRight.y == base.minY)
        #expect(geometry.allPoints.allSatisfy { panel.contains($0) })
        #expect(geometry.apex.y <= panel.maxY)
    }

    @Test
    func geometryHonorsSquashBounds() {
        let base = CGRect(x: 10, y: 10, width: 96, height: 49)
        let neutral = SlimeShapeGeometry.calculate(in: base, spring: .neutral)
        let compressed = SlimeShapeGeometry.calculate(in: base, spring: SlimeSpringState(compression: 1))
        let neutralWidth = neutral.rightShoulder.x - neutral.leftShoulder.x
        let compressedWidth = compressed.rightShoulder.x - compressed.leftShoulder.x
        #expect(compressedWidth <= neutralWidth * 1.06 + 0.001)
        #expect(compressed.apex.y >= base.minY + base.height * 0.93 - 0.001)
    }
}
