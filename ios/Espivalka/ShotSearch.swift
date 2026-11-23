import Foundation

struct ShotSearch {
	static let all = ShotSearch(names: shots)

	private let entries: [(name: String, key: String)]

	init(names: [String]) {
		entries = names.map { ($0, $0.searchKey) }
	}

	func results(for query: String) -> [String] {
		let key = query.trimmingCharacters(in: .whitespacesAndNewlines).searchKey
		guard !key.isEmpty else {
			return entries.map(\.name)
		}
		return entries.filter { $0.key.contains(key) }.map(\.name)
	}
}

private extension String {
	var searchKey: String {
		folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
	}
}
