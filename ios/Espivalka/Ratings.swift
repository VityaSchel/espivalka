import Foundation
import Observation

@Observable
final class Ratings {
	static let scale = 1...5

	private static let storageKey = "ratings"

	private let defaults: UserDefaults
	private(set) var values: [String: Int]

	init(defaults: UserDefaults = .standard) {
		self.defaults = defaults
		values = defaults.dictionary(forKey: Self.storageKey)?.compactMapValues { $0 as? Int } ?? [:]
	}

	subscript(shot: String) -> Int {
		get {
			values[shot] ?? 0
		}
		set {
			values[shot] = newValue
			defaults.set(values, forKey: Self.storageKey)
		}
	}
}
