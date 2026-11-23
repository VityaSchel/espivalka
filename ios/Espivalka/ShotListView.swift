import SwiftUI

struct ShotListView: View {
	@Environment(Ratings.self) private var ratings
	let query: SearchQuery

	var body: some View {
		List {
			Group {
				ForEach(ShotSearch.all.results(for: query.text), id: \.self) { name in
					NavigationLink {
						RatingView(name: name, rating: ratings[name])
							.environment(ratings)
					} label: {
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
		.topBarAttachment {
			RatingProgress(rated: shots.count(where: { ratings[$0] > 0 }), total: shots.count)
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
			.background(Palette.background, ignoresSafeAreaEdges: [])
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
