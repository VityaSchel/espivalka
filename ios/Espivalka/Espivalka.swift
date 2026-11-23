import SwiftUI

@main
struct Espivalka: App {
	@State private var ratings = Ratings()

	init() {
		NavigationBarStyle.apply()
	}

	var body: some Scene {
		WindowGroup {
			NavigationStack {
				ShotListView()
			}
			.tint(Palette.text)
			.environment(ratings)
		}
	}
}
