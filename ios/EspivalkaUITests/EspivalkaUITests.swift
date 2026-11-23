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

		app.swipeUp()
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

	static func launchedWithSeededRatings() -> XCUIApplication {
		let app = XCUIApplication()
		let entries = seededRatings.map { "<key>\($0.key)</key><integer>\($0.value)</integer>" }.joined()
		app.launchArguments = ["-ratings", "<dict>\(entries)</dict>"]
		app.launch()
		return app
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
