import SwiftUI

nonisolated struct WheelDraw: Identifiable {
	static let landingRange = 0.05...0.95
	static let extraTurnsRange = 3...5

	let id = UUID()
	let names: [String]
	let winner: Int
	let landing: Double
	let extraTurns: Int

	var winnerName: String {
		names[winner]
	}

	static func candidates(from names: [String], ratings: [String: Int]) -> [String] {
		let unrated = names.filter { ratings[$0, default: 0] == 0 }
		return unrated.isEmpty ? names : unrated
	}

	static func random(from candidates: [String], using generator: inout some RandomNumberGenerator) -> WheelDraw {
		let names = candidates.shuffled(using: &generator)
		return WheelDraw(
			names: names,
			winner: Int.random(in: names.indices, using: &generator),
			landing: Double.random(in: landingRange, using: &generator),
			extraTurns: Int.random(in: extraTurnsRange, using: &generator)
		)
	}

	func rotation(extraTurns: Int) -> Double {
		Wheel.rotation(landingOn: winner, at: landing, extraTurns: extraTurns, count: names.count)
	}
}

nonisolated enum Wheel {
	static let fullTurn = 2 * Double.pi

	static func sliceAngle(count: Int) -> Double {
		fullTurn / Double(count)
	}

	static func sliceIndex(atRotation rotation: Double, count: Int) -> Int {
		let turns = -rotation / fullTurn
		return min(Int((turns - turns.rounded(.down)) * Double(count)), count - 1)
	}

	static func rotation(landingOn index: Int, at landing: Double, extraTurns: Int, count: Int) -> Double {
		fullTurn * Double(extraTurns + 1) - sliceAngle(count: count) * (Double(index) + landing)
	}

	static func colorIndices(count: Int, paletteSize: Int) -> [Int] {
		var colors = (0..<count).map { $0 % paletteSize }
		if count > 1, colors[count - 1] == colors[0] {
			colors[count - 1] = 1
		}
		return colors
	}

	static func slice(_ index: Int, of count: Int, in rect: CGRect) -> Path {
		let center = CGPoint(x: rect.midX, y: rect.midY)
		let angle = sliceAngle(count: count)
		let start = angle * Double(index) - fullTurn / 4
		return Path { path in
			path.move(to: center)
			path.addArc(
				center: center,
				radius: min(rect.width, rect.height) / 2,
				startAngle: .radians(start),
				endAngle: .radians(start + angle),
				clockwise: false
			)
			path.closeSubpath()
		}
	}
}

nonisolated struct WheelSpin {
	private static let frictionExponent = 3.0
	private static let dampingRatio = 0.4
	private static let springFrequency = 11.0
	private static let maxOvershoot = 0.1
	private static let overshootMargin = 0.9

	let target: Double
	let overshoot: Double
	let spinUp: Double
	let coast: Double
	let settle: Double

	var duration: Double {
		spinUp + coast + settle
	}

	static func physical(for draw: WheelDraw) -> WheelSpin {
		let room = min(draw.landing, (1 - draw.landing) / reboundRatio) * Wheel.sliceAngle(count: draw.names.count)
		return WheelSpin(
			target: draw.rotation(extraTurns: draw.extraTurns),
			overshoot: min(maxOvershoot, overshootMargin * room),
			spinUp: 0.6,
			coast: 5,
			settle: 0.9
		)
	}

	static func reduced(for draw: WheelDraw) -> WheelSpin {
		WheelSpin(target: draw.rotation(extraTurns: 0), overshoot: 0, spinUp: 0, coast: 1.5, settle: 0)
	}

	func rotation(at time: Double) -> Double {
		let coastShare = coast / (Self.frictionExponent + 1)
		let peakVelocity = (target + overshoot) / (spinUp / 2 + coastShare)
		switch time {
		case ..<0:
			return 0
		case ..<spinUp:
			return peakVelocity * time * time / (2 * spinUp)
		case ..<(spinUp + coast):
			let remaining = 1 - (time - spinUp) / coast
			return peakVelocity * (spinUp / 2 + coastShare * (1 - pow(remaining, Self.frictionExponent + 1)))
		case ..<duration:
			return target + overshoot * Self.springDisplacement(at: time - spinUp - coast)
		default:
			return target
		}
	}

	private static var reboundRatio: Double {
		exp(-.pi * dampingRatio / (1 - dampingRatio * dampingRatio).squareRoot())
	}

	private static func springDisplacement(at time: Double) -> Double {
		let decay = dampingRatio * springFrequency
		let frequency = springFrequency * (1 - dampingRatio * dampingRatio).squareRoot()
		return exp(-decay * time) * (cos(frequency * time) + decay / frequency * sin(frequency * time))
	}
}
