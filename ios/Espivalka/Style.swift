import SwiftUI

enum Palette {
	static let background = Color(hex: 0x02000A)
	static let text = Color(hex: 0x13C0FF)
	static let glow = Color(hex: 0x3300FF)
	static let star = Color(hex: 0xFFA100)
	static let buttonBackground = Color(hex: 0x6400FD)
	static let progress = Color.white
	static let separator = glow.opacity(0.6)
	static let scrim = Color.black.opacity(0.65)
	static let wheel = [buttonBackground, text, glow, glow.mix(with: background, by: 0.5)]
}

extension Font {
	static let shotNameFamily = "Comic Sans MS"
	static let shotNameSize: CGFloat = 17
	static let shotName = Font.custom(shotNameFamily, size: shotNameSize, relativeTo: .body)
	static let shotTitleSize: CGFloat = 44
	static let shotTitle = Font.custom(shotNameFamily, size: shotTitleSize, relativeTo: .largeTitle)
}

struct Star: View {
	static let symbol = "star"

	let isFilled: Bool

	var body: some View {
		Image(systemName: Self.symbol)
			.symbolVariant(isFilled ? .fill : .none)
			.fontWeight(isFilled ? .black : .medium)
	}
}

extension Text {
	static func stars(_ count: Int) -> Text {
		Text("^[\(count) star](inflect: true)")
	}
}

struct Glow: ViewModifier {
	static let radius: CGFloat = 4

	@ScaledMetric(relativeTo: .body) private var bodyRadius = Self.radius
	@Environment(\.glowRadius) private var glowRadius

	static func radius(forFontSize fontSize: CGFloat) -> CGFloat {
		fontSize * radius / Font.shotNameSize
	}

	func body(content: Content) -> some View {
		let radius = glowRadius ?? bodyRadius
		return content
			.shadow(color: Palette.glow, radius: radius / 4)
			.shadow(color: Palette.glow, radius: radius / 2)
			.shadow(color: Palette.glow, radius: radius)
	}
}

extension EnvironmentValues {
	@Entry var glowRadius: CGFloat?
}

extension View {
	func glow() -> some View {
		modifier(Glow())
	}

	func inlineTitle(_ title: String) -> some View {
		navigationTitle(title)
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .principal) {
					Text(title)
						.font(.headline)
						.foregroundStyle(Palette.text)
						.glow()
				}
			}
	}

	func accentButton() -> some View {
		buttonStyle(.borderedProminent)
			.accentButtonColors()
	}

	@ViewBuilder
	func floatingAccentButton() -> some View {
		if #available(iOS 26, *) {
			buttonStyle(.glassProminent)
				.accentButtonColors()
		} else {
			accentButton()
				.buttonBorderShape(.capsule)
		}
	}

	private func accentButtonColors() -> some View {
		controlSize(.large)
			.tint(Palette.buttonBackground)
			.foregroundStyle(Palette.text)
	}
}

enum NavigationBarStyle {
	static func apply() {
		let glow = NSShadow()
		glow.shadowColor = UIColor(Palette.glow)
		glow.shadowBlurRadius = Glow.radius
		let title: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor(Palette.text), .shadow: glow]
		let navigationBar = UINavigationBar.appearance()
		if #available(iOS 26, *) {
			navigationBar.titleTextAttributes = title
			navigationBar.largeTitleTextAttributes = title
		} else {
			let appearance = UINavigationBarAppearance()
			appearance.configureWithOpaqueBackground()
			appearance.backgroundColor = UIColor(Palette.background)
			appearance.shadowColor = .clear
			appearance.titleTextAttributes = title
			appearance.largeTitleTextAttributes = title
			navigationBar.standardAppearance = appearance
			navigationBar.scrollEdgeAppearance = appearance
		}
	}
}

private extension Color {
	init(hex: UInt32) {
		self.init(
			.sRGB,
			red: Double(hex >> 16 & 0xFF) / 255,
			green: Double(hex >> 8 & 0xFF) / 255,
			blue: Double(hex & 0xFF) / 255
		)
	}
}
