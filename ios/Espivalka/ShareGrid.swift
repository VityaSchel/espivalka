import CoreGraphics

struct ShareGrid {
	static let aspectRatio: CGFloat = 9 / 16

	let columns: Int
	let rows: Int
	let contentSize: CGSize

	init(itemCount: Int, cellSize: CGSize, columnSpacing: CGFloat, margin: CGFloat) {
		func layout(columnLimit: Int) -> (columns: Int, rows: Int, size: CGSize) {
			let rows = (itemCount + columnLimit - 1) / columnLimit
			let columns = (itemCount + rows - 1) / rows
			let width = CGFloat(columns) * cellSize.width + CGFloat(columns - 1) * columnSpacing
			let height = CGFloat(rows) * cellSize.height
			return (columns, rows, CGSize(width: width + 2 * margin, height: height + 2 * margin))
		}
		let best = (1...itemCount).map(layout).min { $0.size.aspectError < $1.size.aspectError }!
		(columns, rows, contentSize) = best
	}

	var canvasSize: CGSize {
		if contentSize.aspectRatio > Self.aspectRatio {
			CGSize(width: contentSize.width, height: contentSize.width / Self.aspectRatio)
		} else {
			CGSize(width: contentSize.height * Self.aspectRatio, height: contentSize.height)
		}
	}
}

private extension CGSize {
	var aspectRatio: CGFloat {
		width / height
	}

	var aspectError: CGFloat {
		abs(aspectRatio - ShareGrid.aspectRatio)
	}
}
