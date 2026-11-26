import Foundation
import SwiftUI
import Testing
@testable import Espivalka

struct WheelDrawTests {
	@Test func offersOnlyUnratedShots() {
		#expect(WheelDraw.candidates(from: ["A", "B", "C", "D"], ratings: ["A": 3, "C": 1, "D": 0]) == ["B", "D"])
	}

	@Test func offersTheLastUnratedShotAlone() {
		#expect(WheelDraw.candidates(from: ["A", "B", "C"], ratings: ["A": 5, "C": 2]) == ["B"])
	}

	@Test func offersEveryShotOnceAllAreRated() {
		#expect(WheelDraw.candidates(from: ["A", "B"], ratings: ["A": 5, "B": 2]) == ["A", "B"])
	}

	@Test func shufflesWithTheInjectedGenerator() {
		var generator = SeededGenerator(seed: 1)
		var sameSeed = SeededGenerator(seed: 1)
		var otherSeed = SeededGenerator(seed: 2)
		let draw = WheelDraw.random(from: shots, using: &generator)
		#expect(draw.names == WheelDraw.random(from: shots, using: &sameSeed).names)
		#expect(draw.names != WheelDraw.random(from: shots, using: &otherSeed).names)
		#expect(draw.names != shots)
		#expect(draw.names.sorted() == shots.sorted())
	}

	@Test func picksEveryCandidateEquallyOften() {
		var generator = SeededGenerator(seed: 7)
		let candidates = ["A", "B", "C", "D", "E"]
		let draws = 50_000
		var wins: [String: Int] = [:]
		for _ in 0..<draws {
			let draw = WheelDraw.random(from: candidates, using: &generator)
			#expect(WheelDraw.landingRange.contains(draw.landing))
			#expect(WheelDraw.extraTurnsRange.contains(draw.extraTurns))
			wins[draw.winnerName, default: 0] += 1
		}
		for candidate in candidates {
			#expect(abs(Double(wins[candidate, default: 0]) / Double(draws) - 1 / Double(candidates.count)) < 0.01)
		}
	}
}

struct WheelTests {
	@Test(arguments: [1, 2, 5, 629])
	func landingRotationPointsAtTheChosenSlice(count: Int) {
		for index in Set([0, count / 2, count - 1]) {
			for landing in [WheelDraw.landingRange.lowerBound, 0.5, WheelDraw.landingRange.upperBound] {
				let rotation = Wheel.rotation(landingOn: index, at: landing, extraTurns: 4, count: count)
				#expect(Wheel.sliceIndex(atRotation: rotation, count: count) == index)
				#expect(rotation > 4 * Wheel.fullTurn)
			}
		}
	}

	@Test func clockwiseRotationBringsEarlierSlicesUnderThePointer() {
		let quarter = Wheel.fullTurn / 4
		#expect(Wheel.sliceIndex(atRotation: 0, count: 4) == 0)
		#expect(Wheel.sliceIndex(atRotation: -quarter / 2, count: 4) == 0)
		#expect(Wheel.sliceIndex(atRotation: quarter / 2, count: 4) == 3)
		#expect(Wheel.sliceIndex(atRotation: 3 * quarter / 2, count: 4) == 2)
		#expect(Wheel.sliceIndex(atRotation: 7 * quarter / 2 + Wheel.fullTurn, count: 4) == 0)
	}

	@Test func firstSliceStartsAtThePointerAndRunsClockwise() {
		let slice = Wheel.slice(0, of: 4, in: CGRect(x: 0, y: 0, width: 100, height: 100))
		#expect(slice.contains(CGPoint(x: 70, y: 20)))
		#expect(!slice.contains(CGPoint(x: 30, y: 20)))
		#expect(!slice.contains(CGPoint(x: 70, y: 80)))
	}

	@Test func singleSliceFillsTheWheel() {
		let slice = Wheel.slice(0, of: 1, in: CGRect(x: 0, y: 0, width: 100, height: 100))
		for point in [CGPoint(x: 50, y: 10), CGPoint(x: 90, y: 50), CGPoint(x: 50, y: 90), CGPoint(x: 10, y: 50)] {
			#expect(slice.contains(point))
		}
	}

	@Test(arguments: Array(1...20) + [629])
	func neighboringSlicesHaveDifferentColors(count: Int) {
		let colors = Wheel.colorIndices(count: count, paletteSize: Palette.wheel.count)
		#expect(colors.count == count)
		#expect(colors.allSatisfy(Palette.wheel.indices.contains))
		if count > 1 {
			#expect(colors.indices.allSatisfy { colors[$0] != colors[($0 + 1) % count] })
		}
	}
}

struct WheelSpinTests {
	nonisolated private static let landings = [WheelDraw.landingRange.lowerBound, 0.3, 0.5, WheelDraw.landingRange.upperBound]

	@Test(arguments: [1, 2, 5, 629], landings)
	func settlesWithoutLeavingTheChosenSlice(count: Int, landing: Double) {
		let draw = Self.draw(count: count, landing: landing)
		let spin = WheelSpin.physical(for: draw)
		let settleTimes = stride(from: spin.spinUp + spin.coast, through: spin.duration + 1, by: 0.001)
		#expect(spin.overshoot > 0)
		#expect(settleTimes.allSatisfy { Wheel.sliceIndex(atRotation: spin.rotation(at: $0), count: count) == draw.winner })
	}

	@Test(arguments: [false, true])
	func startsAtRestAndStopsExactlyOnTheTarget(reducesMotion: Bool) {
		let draw = Self.draw(count: 629, landing: 0.5)
		let spin = reducesMotion ? WheelSpin.reduced(for: draw) : .physical(for: draw)
		#expect(spin.rotation(at: -1) == 0)
		#expect(spin.rotation(at: 0) == 0)
		#expect(abs(spin.rotation(at: spin.duration - 0.001) - spin.target) < 0.01)
		#expect(spin.rotation(at: spin.duration) == spin.target)
		#expect(Wheel.sliceIndex(atRotation: spin.target, count: 629) == draw.winner)
	}

	@Test func spinsForFiveToEightSecondsUnlessMotionIsReduced() {
		let draw = Self.draw(count: 629, landing: 0.5)
		let physical = WheelSpin.physical(for: draw)
		let reduced = WheelSpin.reduced(for: draw)
		#expect((5...8).contains(physical.duration))
		#expect(reduced.duration < 2)
		#expect(reduced.target < Wheel.fullTurn)
		#expect(physical.target > Double(draw.extraTurns) * Wheel.fullTurn)
	}

	@Test func acceleratesThenCoastsToAStopWithoutReversing() throws {
		let spin = WheelSpin.physical(for: Self.draw(count: 629, landing: 0.5))
		let step = 0.01
		let velocities = stride(from: 0, to: spin.spinUp + spin.coast, by: step).map { time in
			(spin.rotation(at: time + step) - spin.rotation(at: time)) / step
		}
		let peak = try #require(velocities.indices.max { velocities[$0] < velocities[$1] })
		#expect(abs(Double(peak) * step - spin.spinUp) < 2 * step)
		#expect(zip(velocities[...peak], velocities[...peak].dropFirst()).allSatisfy(<))
		#expect(zip(velocities[peak...], velocities[peak...].dropFirst()).allSatisfy(>))
		#expect(try #require(velocities.last) < 0.01)
	}

	private static func draw(count: Int, landing: Double) -> WheelDraw {
		WheelDraw(names: (0..<count).map(String.init), winner: count / 2, landing: landing, extraTurns: 4)
	}
}

private struct SeededGenerator: RandomNumberGenerator {
	private var state: UInt64

	init(seed: UInt64) {
		state = seed
	}

	mutating func next() -> UInt64 {
		state &+= 0x9E37_79B9_7F4A_7C15
		var value = state
		value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
		value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
		return value ^ (value >> 31)
	}
}
