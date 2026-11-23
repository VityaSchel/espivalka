import SwiftUI
import UniformTypeIdentifiers

nonisolated struct ShareImage: Transferable {
	static let title = "Espivalka"
	static let pixelSize = CGSize(width: 2160, height: 3840)

	private static let fileName = "\(title).png"

	let ratings: [String: Int]

	static var transferRepresentation: some TransferRepresentation {
		FileRepresentation(exportedContentType: .png) { image in
			SentTransferredFile(try await image.exportFile())
		}
		.suggestedFileName(fileName)
	}

	@MainActor private static var latestExport: (ratings: [String: Int], file: Task<URL, Error>)?

	@MainActor func exportFile() async throws -> URL {
		if let latest = Self.latestExport, latest.ratings == ratings,
			let url = try? await latest.file.value, FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
			return url
		}
		let file = Task { try await Self.writePNG(render()) }
		Self.latestExport = (ratings, file)
		return try await file.value
	}

	@MainActor private func render() throws -> UIImage {
		let renderer = ImageRenderer(content: ShareCanvas(ratings: ratings))
		renderer.scale = 1
		renderer.isOpaque = true
		guard let image = renderer.uiImage else {
			throw CocoaError(.fileWriteUnknown)
		}
		let format = UIGraphicsImageRendererFormat()
		format.scale = 1
		format.opaque = true
		format.preferredRange = .standard
		return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
			image.draw(at: .zero)
		}
	}

	@concurrent private static func writePNG(_ image: UIImage) async throws -> URL {
		guard let data = image.pngData() else {
			throw CocoaError(.fileWriteUnknown)
		}
		let url = URL.temporaryDirectory.appending(path: fileName)
		try data.write(to: url, options: .atomic)
		return url
	}
}

private struct ShareCanvas: View {
	private static let cellHeight: CGFloat = 1.6
	private static let nameGap: CGFloat = 2
	private static let columnSpacing: CGFloat = 2
	private static let margin: CGFloat = 2

	let ratings: [String: Int]

	private let grid: ShareGrid
	private let cellWidth: CGFloat
	private let fontSize: CGFloat

	init(ratings: [String: Int]) {
		self.ratings = ratings
		cellWidth = Self.cellWidthInEms()
		grid = ShareGrid(
			itemCount: shots.count,
			cellSize: CGSize(width: cellWidth, height: Self.cellHeight),
			columnSpacing: Self.columnSpacing,
			margin: Self.margin
		)
		fontSize = ShareImage.pixelSize.width / grid.canvasSize.width
	}

	var body: some View {
		HStack(alignment: .top, spacing: Self.columnSpacing * fontSize) {
			ForEach(0..<grid.columns, id: \.self) { column in
				VStack(spacing: 0) {
					ForEach(shots[column * grid.rows ..< min((column + 1) * grid.rows, shots.count)], id: \.self) { name in
						ShotLabel(name: name, rating: ratings[name] ?? 0)
							.frame(width: cellWidth * fontSize, height: Self.cellHeight * fontSize)
					}
				}
			}
		}
		.font(.custom(Font.shotNameFamily, fixedSize: fontSize))
		.frame(width: ShareImage.pixelSize.width, height: ShareImage.pixelSize.height)
		.background(Palette.background)
	}

	private static func cellWidthInEms() -> CGFloat {
		let referenceSize: CGFloat = 100
		let font = UIFont(name: Font.shotNameFamily, size: referenceSize) ?? .systemFont(ofSize: referenceSize)
		let nameWidth = shots.map { ($0.uppercased() as NSString).size(withAttributes: [.font: font]).width }.max() ?? 0
		let starConfiguration = UIImage.SymbolConfiguration(font: font).applying(UIImage.SymbolConfiguration(weight: .black))
		let starWidth = UIImage(systemName: Star.symbol, withConfiguration: starConfiguration)?.size.width ?? referenceSize
		let starsWidth = CGFloat(Ratings.scale.upperBound) * starWidth
		return (nameWidth + starsWidth) / referenceSize + nameGap
	}
}
