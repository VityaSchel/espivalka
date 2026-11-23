import SwiftUI

enum Palette {
	static let background = Color(hex: 0x02000A)
	static let text = Color.accent
	static let glow = Color(hex: 0x3300FF)
	static let star = Color(hex: 0xFFA100)
	static let buttonBackground = Color(hex: 0x6400FD)
	static let progress = Color.white
	static let separator = glow.opacity(0.6)
}

extension Font {
	static let shotNameFamily = "Comic Sans MS"
	static let shotName = Font.custom(shotNameFamily, size: 17, relativeTo: .body)
}

extension String {
	static let starSymbol = "star"
}

extension Text {
	static func stars(_ count: Int) -> Text {
		Text("^[\(count) star](inflect: true)")
	}
}

struct Glow: ViewModifier {
	static let radius: CGFloat = 4

	@ScaledMetric(relativeTo: .body) private var radius = Self.radius

	func body(content: Content) -> some View {
		content
			.shadow(color: Palette.glow, radius: radius / 4)
			.shadow(color: Palette.glow, radius: radius / 4)
			.shadow(color: Palette.glow, radius: radius / 2)
			.shadow(color: Palette.glow, radius: radius / 2)
			.shadow(color: Palette.glow, radius: radius)
	}
}

extension View {
	func glow() -> some View {
		modifier(Glow())
	}

	func accentButton() -> some View {
		buttonStyle(.borderedProminent)
			.controlSize(.large)
			.tint(Palette.buttonBackground)
			.foregroundStyle(Palette.text)
	}
}

enum NavigationBarStyle {
	static func apply() {
		let appearance = UINavigationBarAppearance()
		appearance.configureWithOpaqueBackground()
		appearance.backgroundColor = UIColor(Palette.background)
		appearance.shadowColor = .clear

		let glow = NSShadow()
		glow.shadowColor = UIColor(Palette.glow)
		glow.shadowBlurRadius = Glow.radius
		let title: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor(Palette.text), .shadow: glow]
		appearance.titleTextAttributes = title
		appearance.largeTitleTextAttributes = title

		let navigationBar = UINavigationBar.appearance()
		navigationBar.standardAppearance = appearance
		navigationBar.scrollEdgeAppearance = appearance
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
