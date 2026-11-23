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
	@Test func picksColumnCountClosestToNineBySixteen() {
		let grid = ShareGrid(itemCount: 16, cellSize: CGSize(width: 1, height: 1), columnSpacing: 0, margin: 0)
		#expect(grid.columns == 3)
		#expect(grid.rows == 6)
		#expect(grid.contentSize == CGSize(width: 3, height: 6))
		#expect(grid.canvasSize == CGSize(width: 3.375, height: 6))
	}

	@Test func countsSpacingAndMargins() {
		let grid = ShareGrid(itemCount: 12, cellSize: CGSize(width: 2, height: 1), columnSpacing: 1, margin: 1)
		#expect(grid.columns == 1)
		#expect(grid.contentSize == CGSize(width: 4, height: 14))
		#expect(grid.canvasSize == CGSize(width: 7.875, height: 14))
	}

	@Test func padsWideContentVertically() {
		let grid = ShareGrid(itemCount: 1, cellSize: CGSize(width: 9, height: 1), columnSpacing: 0, margin: 0)
		#expect(grid.canvasSize == CGSize(width: 9, height: 16))
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
