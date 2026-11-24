import CoreGraphics

struct ShareGrid {
	static let aspectRatio: CGFloat = 9 / 16

	let rows: Int
	let columnWidths: [CGFloat]
	let rowHeight: CGFloat
	let width: CGFloat

	init(itemWidths: [CGFloat], columns: Int, columnSpacing: CGFloat, margin: CGFloat) {
		let rows = (itemWidths.count + columns - 1) / columns
		self.rows = rows
		columnWidths = stride(from: 0, to: itemWidths.count, by: rows).map { start in
			itemWidths[start..<min(start + rows, itemWidths.count)].max()!
		}
		width = columnWidths.reduce(0, +) + CGFloat(columnWidths.count - 1) * columnSpacing + 2 * margin
		rowHeight = (width / Self.aspectRatio - 2 * margin) / CGFloat(rows)
	}

	func items(inColumn column: Int, of count: Int) -> Range<Int> {
		column * rows..<min((column + 1) * rows, count)
	}
}
