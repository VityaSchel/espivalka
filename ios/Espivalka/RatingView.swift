import SwiftUI

struct RatingView: View {
	nonisolated private static let saveSpacing: CGFloat = 32

	let name: String

	@Environment(Ratings.self) private var ratings
	@Environment(\.dismiss) private var dismiss
	@State private var rating: Int

	init(name: String, rating: Int) {
		self.name = name
		_rating = State(initialValue: rating)
	}

	var body: some View {
		StarPicker(rating: $rating)
			.overlay(alignment: .bottom) {
				Button("Save") {
					ratings[name] = rating
					dismiss()
				}
				.accentButton()
				.disabled(rating == 0)
				.fixedSize()
				.alignmentGuide(.bottom) { $0[.top] - Self.saveSpacing }
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(Palette.background)
			.navigationTitle(name)
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .principal) {
					Text(name)
						.font(.headline)
						.foregroundStyle(Palette.text)
						.glow()
				}
			}
	}
}

struct StarPicker: View {
	static let starWidth: CGFloat = 56

	@Binding var rating: Int

	var body: some View {
		HStack(spacing: 0) {
			ForEach(Ratings.scale, id: \.self) { star in
				let isFilled = star <= rating
				Star(isFilled: isFilled)
					.font(.system(size: 44))
					.foregroundStyle(isFilled ? Palette.star : Palette.text)
					.frame(width: Self.starWidth, height: Self.starWidth)
			}
		}
		.contentShape(.rect)
		.gesture(DragGesture(minimumDistance: 0).onChanged { rating = Self.rating(at: $0.location.x) })
		.accessibilityElement()
		.accessibilityLabel("Rating")
		.accessibilityValue(Text.stars(rating))
		.accessibilityAdjustableAction { direction in
			switch direction {
			case .increment where rating < Ratings.scale.upperBound:
				rating += 1
			case .decrement where rating > Ratings.scale.lowerBound:
				rating -= 1
			default:
				break
			}
		}
	}

	static func rating(at x: CGFloat) -> Int {
		min(max(Int((x / starWidth).rounded(.up)), Ratings.scale.lowerBound), Ratings.scale.upperBound)
	}
}
