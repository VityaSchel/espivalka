package dev.hloth.espivalka

import kotlin.math.abs
import kotlin.math.max

data class ShareGrid(
	val columns: Int,
	val rows: Int,
	val width: Float,
	val height: Float,
	val cellWidth: Float,
	val cellHeight: Float,
	val columnGap: Float,
	val contentLeft: Float,
	val contentTop: Float,
) {
	fun cellLeft(index: Int) = contentLeft + index / rows * (cellWidth + columnGap)

	fun cellTop(index: Int) = contentTop + index % rows * cellHeight
}

fun shareGrid(
	itemCount: Int,
	cellWidth: Float,
	cellHeight: Float,
	columnGap: Float,
	margin: Float,
	aspectRatio: Float,
): ShareGrid {
	fun contentWidth(columns: Int) = 2 * margin + columns * cellWidth + (columns - 1) * columnGap
	fun contentHeight(rows: Int) = 2 * margin + rows * cellHeight

	val rows = (1..itemCount).map { ceilDiv(itemCount, it) }.distinct().minBy { rows ->
		abs(contentWidth(ceilDiv(itemCount, rows)) / contentHeight(rows) - aspectRatio)
	}
	val columns = ceilDiv(itemCount, rows)
	val contentWidth = contentWidth(columns)
	val contentHeight = contentHeight(rows)
	val width = max(contentWidth, contentHeight * aspectRatio)
	val height = width / aspectRatio
	return ShareGrid(
		columns = columns,
		rows = rows,
		width = width,
		height = height,
		cellWidth = cellWidth,
		cellHeight = cellHeight,
		columnGap = columnGap,
		contentLeft = (width - contentWidth) / 2 + margin,
		contentTop = (height - contentHeight) / 2 + margin,
	)
}

private fun ceilDiv(dividend: Int, divisor: Int) = (dividend + divisor - 1) / divisor
