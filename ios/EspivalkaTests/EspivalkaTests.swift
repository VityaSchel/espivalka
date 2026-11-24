import Foundation
import Testing
import SwiftUI
@testable import Espivalka

struct ShotsTests {
	@Test func containsEveryShotOnce() {
		#expect(shots.count == 629)
		#expect(Set(shots).count == shots.count)
	}

	@Test func registersShotNameFont() {
		#expect(UIFont(name: Font.shotNameFamily, size: 17)?.fontName == "ComicSansMS")
	}
}

struct ShotSearchTests {
	@Test(arguments: ["", " ", "\n"])
	func blankQueryReturnsAllShotsInOrder(query: String) {
		#expect(ShotSearch.all.results(for: query) == shots)
	}

	@Test(arguments: [("fenix", "FÉNIX"), ("barca", "BARÇA"), ("canero", "CAÑERO"), ("ultimo", "EL ÚLTIMO"), ("FéNiX", "FÉNIX"), (" fenix ", "FÉNIX")])
	func ignoresCaseAndDiacritics(query: String, expected: String) {
		#expect(ShotSearch.all.results(for: query).contains(expected))
	}

	@Test func matchesSubstringsInOriginalOrder() {
		let search = ShotSearch(names: ["ÁBACO", "Caballo", "PERRO"])
		#expect(search.results(for: "ab") == ["ÁBACO", "Caballo"])
		#expect(search.results(for: "gato").isEmpty)
	}
}

struct RatingsTests {
	@Test func persistsRatings() throws {
		let suiteName = "RatingsTests"
		let defaults = try #require(UserDefaults(suiteName: suiteName))
		defaults.removePersistentDomain(forName: suiteName)
		Ratings(defaults: defaults)["FÉNIX"] = 4
		let restored = Ratings(defaults: defaults)
		#expect(restored["FÉNIX"] == 4)
		#expect(restored["BARÇA"] == 0)
	}
}

struct StarPickerTests {
	@Test func selectsStarUnderFinger() {
		#expect(StarPicker.rating(at: -10) == 1)
		#expect(StarPicker.rating(at: 0) == 1)
		#expect(StarPicker.rating(at: StarPicker.starWidth * 2.5) == 3)
		#expect(StarPicker.rating(at: StarPicker.starWidth * 3) == 3)
		#expect(StarPicker.rating(at: StarPicker.starWidth * 9) == 5)
	}
}

struct ShareGridTests {
	@Test func columnsAreAsWideAsTheirWidestItem() {
		let grid = ShareGrid(itemWidths: [1, 1, 2, 2, 3, 3, 4], columns: 4, columnSpacing: 1, margin: 1)
		#expect(grid.rows == 2)
		#expect(grid.columnWidths == [1, 2, 3, 4])
		#expect(grid.width == 15)
	}

	@Test func rowsFillTheHeightBetweenTheMargins() {
		let grid = ShareGrid(itemWidths: [CGFloat](repeating: 2, count: 12), columns: 3, columnSpacing: 0, margin: 1)
		#expect(grid.rows == 4)
		#expect(grid.width == 8)
		#expect(abs(CGFloat(grid.rows) * grid.rowHeight - (8 / ShareGrid.aspectRatio - 2)) < 0.001)
	}

	@Test func columnsFlowTopToBottomThenLeftToRight() {
		let grid = ShareGrid(itemWidths: [CGFloat](repeating: 1, count: shots.count), columns: 6, columnSpacing: 1, margin: 1)
		#expect(grid.items(inColumn: 0, of: shots.count) == 0..<grid.rows)
		#expect(grid.items(inColumn: 5, of: shots.count).upperBound == shots.count)
	}
}

struct ShareImageTests {
	@Test func exportsFullResolutionPNG() async throws {
		let ratings = Dictionary(uniqueKeysWithValues: shots.enumerated().filter { $0.offset % 3 == 0 }.map { ($0.element, $0.offset % 5 + 1) })
		let url = try await ShareImage(ratings: ratings).exportFile()
		let data = try Data(contentsOf: url)
		let image = try #require(UIImage(data: data))
		#expect(url.lastPathComponent == "Espivalka.png")
		#expect(image.size == ShareImage.pixelSize)
		Attachment.record(data, named: "share.png")
	}
}
