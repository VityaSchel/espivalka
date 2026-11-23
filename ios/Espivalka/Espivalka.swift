import SwiftUI

@main
struct Espivalka: App {
	@State private var ratings = Ratings()

	init() {
		NavigationBarStyle.apply()
	}

	var body: some Scene {
		WindowGroup {
			ShotNavigation(ratings: ratings)
				.ignoresSafeArea()
		}
	}
}
