import SwiftUI

struct ShotNavigation: UIViewControllerRepresentable {
	let ratings: Ratings

	func makeUIViewController(context: Context) -> UINavigationController {
		let navigation = UINavigationController(rootViewController: ShotListController(ratings: ratings))
		navigation.navigationBar.prefersLargeTitles = true
		navigation.view.tintColor = UIColor(Palette.text)
		return navigation
	}

	func updateUIViewController(_ navigation: UINavigationController, context: Context) {}
}

@Observable
final class SearchQuery {
	var text = ""
}

struct ShotListRoot: View {
	let ratings: Ratings
	let query: SearchQuery
	var spinWheel: () -> Void = {}

	var body: some View {
		ShotListView(query: query, spinWheel: spinWheel)
			.environment(ratings)
	}
}

final class ShotListController: UIHostingController<ShotListRoot>, UISearchResultsUpdating {
	private let ratings: Ratings
	private let query = SearchQuery()

	init(ratings: Ratings) {
		self.ratings = ratings
		super.init(rootView: ShotListRoot(ratings: ratings, query: query))
		rootView.spinWheel = { [weak self] in
			self?.spinWheel()
		}
		title = "Espivalka"
		view.backgroundColor = UIColor(Palette.background)
		let search = UISearchController(searchResultsController: nil)
		search.obscuresBackgroundDuringPresentation = false
		search.searchResultsUpdater = self
		search.searchBar.placeholder = "Search"
		search.searchBar.autocorrectionType = .no
		search.searchBar.spellCheckingType = .no
		search.searchBar.autocapitalizationType = .none
		navigationItem.searchController = search
		navigationItem.hidesSearchBarWhenScrolling = false
		navigationItem.preferredSearchBarPlacement = .stacked
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError()
	}

	func updateSearchResults(for searchController: UISearchController) {
		query.text = searchController.searchBar.text ?? ""
	}

	private func spinWheel() {
		var generator = SystemRandomNumberGenerator()
		let draw = WheelDraw.random(from: WheelDraw.candidates(from: shots, ratings: ratings.values), using: &generator)
		let wheel = RandomController(draw: draw) { [weak self] in
			self?.openRating(of: draw.winnerName)
		}
		navigationController?.pushViewController(wheel, animated: true)
	}

	private func openRating(of name: String) {
		let rating = UIHostingController(rootView: RatingScreen(name: name, ratings: ratings))
		navigationController?.setViewControllers([self, rating], animated: true)
	}
}

final class RandomController: UIHostingController<RandomView> {
	init(draw: WheelDraw, openRating: @escaping () -> Void) {
		super.init(rootView: RandomView(draw: draw, openRating: openRating))
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if rootView.start == nil {
			rootView.start = .now
		}
	}
}
