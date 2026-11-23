import SwiftUI

struct ShotLabel: View {
	private static let stackedSize = DynamicTypeSize.xxLarge

	let name: String
	let rating: Int

	@Environment(\.dynamicTypeSize) private var dynamicTypeSize

	private var layout: AnyLayout {
		dynamicTypeSize >= Self.stackedSize ? AnyLayout(VStackLayout(alignment: .trailing)) : AnyLayout(HStackLayout())
	}

	var body: some View {
		layout {
			Text(name.uppercased())
				.foregroundStyle(Palette.text)
				.glow()
				.frame(maxWidth: .infinity, alignment: .leading)
			if rating > 0 {
				HStack(spacing: 2) {
					ForEach(0..<rating, id: \.self) { _ in
						Image(systemName: .starSymbol)
					}
				}
				.symbolVariant(.fill)
				.foregroundStyle(Palette.star)
				.accessibilityElement(children: .ignore)
				.accessibilityLabel(Text.stars(rating))
			}
		}
	}
}
