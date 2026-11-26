import SwiftUI

struct RandomView: View {
	private static let pointerSize = CGSize(width: 28, height: 24)

	let draw: WheelDraw
	let openRating: () -> Void
	var start: Date?

	@Environment(\.accessibilityReduceMotion) private var reducesMotion
	@State private var hasLanded = false

	private var spin: WheelSpin {
		reducesMotion ? .reduced(for: draw) : .physical(for: draw)
	}

	var body: some View {
		TimelineView(.animation(paused: start == nil || hasLanded)) { timeline in
			let rotation = spin.rotation(at: spinTime(at: timeline.date))
			let name = draw.names[Wheel.sliceIndex(atRotation: rotation, count: draw.names.count)]
			VStack(spacing: 16) {
				ShotName(name: name)
					.lineLimit(1)
					.minimumScaleFactor(0.3)
				ZStack(alignment: .top) {
					WheelFace(count: draw.names.count)
						.rotationEffect(.radians(rotation))
						.overlay {
							Circle()
								.strokeBorder(Palette.text, lineWidth: 3)
								.glow()
						}
						.padding(.top, Self.pointerSize.height / 2)
					Pointer()
						.fill(Palette.star)
						.frame(width: Self.pointerSize.width, height: Self.pointerSize.height)
				}
			}
			.accessibilityElement(children: .ignore)
			.accessibilityLabel("Wheel")
			.accessibilityValue(name)
			.accessibilityAddTraits(.updatesFrequently)
		}
		.padding()
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.overlay {
			if hasLanded {
				RandomResult(name: draw.winnerName, openRating: openRating)
					.transition(.opacity)
			}
		}
		.font(.shotTitle)
		.environment(\.glowRadius, Glow.radius(forFontSize: Font.shotTitleSize))
		.background(Palette.background)
		.inlineTitle(hasLanded ? "" : "Random")
		.navigationBarBackButtonHidden(hasLanded)
		.navigationBarBackgroundHidden()
		.task(id: start) {
			guard let start else {
				return
			}
			try? await Task.sleep(for: .seconds(spin.duration - Date.now.timeIntervalSince(start)))
			if !Task.isCancelled {
				land()
			}
		}
	}

	private func spinTime(at date: Date) -> Double {
		guard let start else {
			return 0
		}
		return hasLanded ? spin.duration : date.timeIntervalSince(start)
	}

	private func land() {
		withAnimation {
			hasLanded = true
		}
		AccessibilityNotification.Announcement("Landed on \(draw.winnerName)").post()
	}
}

private struct WheelFace: View {
	private static let hubInset = 0.44

	let count: Int

	var body: some View {
		Canvas { context, size in
			let rect = CGRect(origin: .zero, size: size)
			let colors = Wheel.colorIndices(count: count, paletteSize: Palette.wheel.count)
			for (colorIndex, color) in Palette.wheel.enumerated() {
				var slices = Path()
				for slice in colors.indices where colors[slice] == colorIndex {
					slices.addPath(Wheel.slice(slice, of: count, in: rect))
				}
				context.fill(slices, with: .color(color))
			}
			let hub = Path(ellipseIn: rect.insetBy(dx: size.width * Self.hubInset, dy: size.height * Self.hubInset))
			context.fill(hub, with: .color(Palette.background))
			context.stroke(hub, with: .color(Palette.text), lineWidth: 2)
		}
		.aspectRatio(1, contentMode: .fit)
	}
}

nonisolated private struct Pointer: Shape {
	func path(in rect: CGRect) -> Path {
		Path { path in
			path.move(to: CGPoint(x: rect.minX, y: rect.minY))
			path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
			path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
			path.closeSubpath()
		}
	}
}

private struct RandomResult: View {
	let name: String
	let openRating: () -> Void

	var body: some View {
		Button(action: openRating) {
			ShotName(name: name)
				.multilineTextAlignment(.center)
				.minimumScaleFactor(0.5)
				.padding()
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.background(Palette.scrim)
		}
		.buttonStyle(.plain)
		.ignoresSafeArea()
		.accessibilityIdentifier("RandomResult")
		.accessibilityLabel(name)
		.accessibilityHint("Opens the rating screen")
		.accessibilityAddTraits(.isModal)
	}
}

private extension View {
	@ViewBuilder
	func navigationBarBackgroundHidden() -> some View {
		if #available(iOS 26, *) {
			self
		} else {
			toolbarBackground(.hidden, for: .navigationBar)
		}
	}
}
