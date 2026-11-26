import XCTest

nonisolated final class EspivalkaUITests: XCTestCase {
	override func setUp() {
		continueAfterFailure = false
	}

	@MainActor
	func testRatingKeepsSearch() {
		let app = XCUIApplication.launchedWithSeededRatings()
		capture("list")

		app.search("canero")
		capture("filtered")

		app.staticTexts["CAÑERO"].tap()
		XCTAssertTrue(app.searchFields["Search"].waitForNonExistence(timeout: 5))
		let save = app.buttons["Save"]
		let stars = app.descendants(matching: .any)["Rating"]
		XCTAssertFalse(save.isEnabled)
		XCTAssertEqual(stars.value as? String, "0 stars")
		capture("rating-unrated")

		stars.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
			.press(forDuration: 0.2, thenDragTo: stars.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
		XCTAssertEqual(stars.value as? String, "3 stars")
		XCTAssertTrue(save.isEnabled)
		capture("rating-selected")

		save.tap()
		XCTAssertEqual(app.searchFields["Search"].value as? String, "canero")
		XCTAssertTrue(app.staticTexts["CAÑERO"].waitForExistence(timeout: 5))
		capture("saved")
	}

	@MainActor
	func testLargeTitleCollapsesOnScroll() {
		let app = XCUIApplication.launchedWithSeededRatings()
		let bar = app.navigationBars["Espivalka"]
		XCTAssertTrue(bar.waitForExistence(timeout: 5))
		let expandedHeight = bar.frame.height
		capture("title-expanded")

		for _ in 0..<3 where bar.frame.height >= expandedHeight {
			app.swipeUp()
		}
		capture("title-collapsed")
		XCTAssertTrue(app.searchFields["Search"].isHittable)
		XCTAssertLessThan(bar.frame.height, expandedHeight)
	}

	@MainActor
	func testShareOpensShareSheet() {
		let app = XCUIApplication.launchedWithSeededRatings()
		app.search("fenix")
		app.buttons["Share"].tap()
		XCTAssertTrue(app.descendants(matching: .any)["Save Image"].waitForExistence(timeout: 30))
		capture("share-sheet")
	}

	@MainActor
	func testRandomWheelOpensRatingOfLandedShot() {
		let app = XCUIApplication.launchedWithSeededRatings()
		let random = app.buttons["Random"]
		XCTAssertTrue(random.waitForExistence(timeout: 5))
		capture("random-button")

		random.tap()
		let wheel = app.navigationBars["Random"]
		XCTAssertTrue(wheel.waitForExistence(timeout: 5))
		XCTAssertTrue(wheel.buttons.firstMatch.isHittable)
		XCTAssertTrue(app.descendants(matching: .any)["Wheel"].exists)
		capture("random-spinning")

		let result = app.waitForRandomResult()
		XCTAssertFalse(app.navigationBars.buttons.firstMatch.exists)
		capture("random-landed")

		let name = result.label
		result.tap()
		let rating = app.navigationBars[name]
		XCTAssertTrue(rating.waitForExistence(timeout: 5))
		XCTAssertTrue(rating.staticTexts[name].exists)
		XCTAssertTrue(app.descendants(matching: .any)["Rating"].exists)
		capture("random-rating")

		rating.buttons.firstMatch.tap()
		XCTAssertTrue(app.navigationBars["Espivalka"].waitForExistence(timeout: 5))
		XCTAssertTrue(random.isHittable)
		capture("random-list")
	}

	@MainActor
	func testRandomWheelOffersTheLastUnratedShot() {
		let unrated = "CAÑERO"
		let app = XCUIApplication.launched(ratings: Dictionary(uniqueKeysWithValues: shots.filter { $0 != unrated }.map { ($0, 1) }))
		app.search("canero")
		app.buttons["Random"].tap()

		let result = app.waitForRandomResult()
		XCTAssertEqual(result.label, unrated)
		capture("random-last-unrated")

		result.tap()
		XCTAssertTrue(app.navigationBars[unrated].waitForExistence(timeout: 5))
		let stars = app.descendants(matching: .any)["Rating"]
		stars.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
		XCTAssertEqual(stars.value as? String, "5 stars")

		app.buttons["Save"].tap()
		XCTAssertTrue(app.navigationBars["Espivalka"].waitForExistence(timeout: 5))
		XCTAssertEqual(app.searchFields["Search"].value as? String, "canero")
		XCTAssertTrue(app.staticTexts[unrated].exists)
		capture("random-rated-last-unrated")
	}

	@MainActor
	func testBackDuringSpinReturnsToList() {
		let app = XCUIApplication.launchedWithSeededRatings()
		app.search("fenix")
		app.buttons["Random"].tap()
		let wheel = app.navigationBars["Random"]
		XCTAssertTrue(wheel.waitForExistence(timeout: 5))

		wheel.buttons.firstMatch.tap()
		XCTAssertTrue(app.navigationBars["Espivalka"].waitForExistence(timeout: 5))
		XCTAssertTrue(app.descendants(matching: .any)["Wheel"].waitForNonExistence(timeout: 5))
		XCTAssertEqual(app.searchFields["Search"].value as? String, "fenix")
		XCTAssertTrue(app.staticTexts["FÉNIX"].exists)
		capture("random-back-during-spin")
	}

	@MainActor
	private func capture(_ name: String) {
		let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
		attachment.name = name
		attachment.lifetime = .keepAlways
		add(attachment)
	}
}

private extension XCUIApplication {
	static let seededRatings = [
		"67": 5, "93": 3, "JJ": 1, "KO": 4, "666": 2, "EDU": 5, "EVA": 4, "LCD": 3,
		"PROPOSICIÓN INDECENTE": 5, "FÉNIX": 5, "BARÇA": 4, "EL ÚLTIMO": 2,
	]
	static let fadeDuration: TimeInterval = 1

	static func launchedWithSeededRatings() -> XCUIApplication {
		launched(ratings: seededRatings)
	}

	static func launched(ratings: [String: Int]) -> XCUIApplication {
		let app = XCUIApplication()
		let entries = ratings.map { "<key>\($0.key.replacing("&", with: "&amp;"))</key><integer>\($0.value)</integer>" }.joined()
		app.launchArguments = ["-ratings", "<dict>\(entries)</dict>"]
		app.launch()
		return app
	}

	func waitForRandomResult() -> XCUIElement {
		let result = buttons["RandomResult"]
		XCTAssertTrue(result.waitForExistence(timeout: 30))
		Thread.sleep(forTimeInterval: Self.fadeDuration)
		return result
	}

	func search(_ query: String) {
		let field = searchFields["Search"]
		field.tap()
		for character in query {
			field.typeText(String(character))
		}
		XCTAssertEqual(field.value as? String, query)
	}
}
