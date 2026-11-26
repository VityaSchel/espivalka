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
			ShotName(name: name)
				.frame(maxWidth: .infinity, alignment: .leading)
			if rating > 0 {
				HStack(spacing: 2) {
					ForEach(0..<rating, id: \.self) { _ in
						Star(isFilled: true)
					}
				}
				.foregroundStyle(Palette.star)
				.accessibilityElement(children: .ignore)
				.accessibilityLabel(Text.stars(rating))
			}
		}
	}
}

struct ShotName: View {
	let name: String

	var body: some View {
		Text(name.uppercased())
			.foregroundStyle(Palette.text)
			.glow()
	}
}
