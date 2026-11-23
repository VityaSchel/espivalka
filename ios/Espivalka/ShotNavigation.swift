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

	var body: some View {
		ShotListView(query: query)
			.environment(ratings)
	}
}

final class ShotListController: UIHostingController<ShotListRoot>, UISearchResultsUpdating {
	private let query = SearchQuery()

	init(ratings: Ratings) {
		super.init(rootView: ShotListRoot(ratings: ratings, query: query))
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
}
