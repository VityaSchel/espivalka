package dev.hloth.espivalka

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ShareGridTest {
	private val columns = 6
	private val aspectRatio = 9f / 16f
	private val columnGap = 1.5f
	private val margin = 1.5f
	private val itemWidths = shots.map { it.length.toFloat() }

	private fun grid(itemWidths: List<Float> = this.itemWidths) = shareGrid(itemWidths, columns, columnGap, margin, aspectRatio)

	@Test
	fun canvasIsExactlyNineBySixteen() {
		val grid = grid()
		assertEquals(aspectRatio, grid.width / grid.height, 1e-5f)
	}

	@Test
	fun everyItemFitsWithoutEmptyColumns() {
		val grid = grid()
		assertEquals(columns, grid.columnWidths.size)
		assertTrue(columns * grid.rows >= itemWidths.size)
		assertTrue((columns - 1) * grid.rows < itemWidths.size)
	}

	@Test
	fun columnsAreAsWideAsTheirWidestItem() {
		val grid = grid(listOf(1f, 1f, 2f, 2f, 3f, 3f, 4f))
		assertEquals(2, grid.rows)
		assertEquals(listOf(1f, 2f, 3f, 4f), grid.columnWidths)
	}

	@Test
	fun rowsFillTheHeightBetweenTheMargins() {
		val grid = grid()
		assertEquals(grid.height - 2 * margin, grid.rows * grid.rowHeight, 1e-2f)
	}

	@Test
	fun cellsFlowTopToBottomThenLeftToRight() {
		val grid = grid()
		assertEquals(margin, grid.cellLeft(0))
		assertEquals(margin, grid.cellTop(0))
		assertEquals(grid.cellLeft(0), grid.cellLeft(1))
		assertEquals(margin + grid.rowHeight, grid.cellTop(1), 1e-4f)
		assertEquals(grid.cellRight(0) + columnGap, grid.cellLeft(grid.rows), 1e-4f)
		assertEquals(margin, grid.cellTop(grid.rows))
		assertEquals(grid.width - margin, grid.cellRight(itemWidths.lastIndex), 1e-2f)
	}

	@Test
	fun singleItemFillsItsColumn() {
		val grid = grid(listOf(20f))
		assertEquals(1, grid.rows)
		assertEquals(20f + 2 * margin, grid.width)
		assertEquals(margin, grid.cellLeft(0))
		assertEquals(margin + 20f, grid.cellRight(0))
	}
}
