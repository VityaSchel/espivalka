import SwiftUI

struct ShotListView: View {
	@Environment(Ratings.self) private var ratings
	@State private var query = ""

	var body: some View {
		List {
			Group {
				ForEach(ShotSearch.all.results(for: query), id: \.self) { name in
					NavigationLink(value: name) {
						ShotLabel(name: name, rating: ratings[name])
							.font(.shotName)
					}
				}
				.listRowSeparatorTint(Palette.separator)
				ShareLink(item: ShareImage(ratings: ratings.values), preview: SharePreview(ShareImage.title)) {
					Label("Share", systemImage: "square.and.arrow.up")
				}
				.accentButton()
				.frame(maxWidth: .infinity)
				.listRowSeparator(.hidden)
			}
			.listRowBackground(Palette.background)
		}
		.listStyle(.plain)
		.scrollContentBackground(.hidden)
		.background(Palette.background)
		.navigationTitle("Espivalka")
		.navigationBarTitleDisplayMode(.large)
		.searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search")
		.autocorrectionDisabled()
		.topBarAttachment {
			RatingProgress(rated: shots.count(where: { ratings[$0] > 0 }), total: shots.count)
		}
		.navigationDestination(for: String.self) { name in
			RatingView(name: name, rating: ratings[name])
		}
	}
}

private struct RatingProgress: View {
	let rated: Int
	let total: Int

	var body: some View {
		Palette.progress
			.scaleEffect(x: CGFloat(rated) / CGFloat(total), anchor: .leading)
			.frame(height: 3)
			.background(Palette.background)
			.accessibilityElement()
			.accessibilityLabel("Rated shots")
			.accessibilityValue("\(rated) of \(total)")
	}
}

private extension View {
	@ViewBuilder
	func topBarAttachment(@ViewBuilder content: () -> some View) -> some View {
		if #available(iOS 26, *) {
			safeAreaBar(edge: .top, spacing: 0, content: content)
		} else {
			safeAreaInset(edge: .top, spacing: 0, content: content)
		}
	}
}
