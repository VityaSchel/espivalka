package dev.hloth.espivalka

data class ShareGrid(
	val rows: Int,
	val columnWidths: List<Float>,
	val columnLefts: List<Float>,
	val width: Float,
	val height: Float,
	val rowHeight: Float,
	val margin: Float,
) {
	fun cellLeft(index: Int) = columnLefts[index / rows]

	fun cellRight(index: Int) = cellLeft(index) + columnWidths[index / rows]

	fun cellTop(index: Int) = margin + index % rows * rowHeight
}

fun shareGrid(
	itemWidths: List<Float>,
	columns: Int,
	columnGap: Float,
	margin: Float,
	aspectRatio: Float,
): ShareGrid {
	val rows = (itemWidths.size + columns - 1) / columns
	val columnWidths = itemWidths.chunked(rows) { it.max() }
	val width = columnWidths.sum() + (columnWidths.size - 1) * columnGap + 2 * margin
	val height = width / aspectRatio
	return ShareGrid(
		rows = rows,
		columnWidths = columnWidths,
		columnLefts = columnWidths.runningFold(margin) { left, columnWidth -> left + columnWidth + columnGap }.dropLast(1),
		width = width,
		height = height,
		rowHeight = (height - 2 * margin) / rows,
		margin = margin,
	)
}
