package dev.hloth.espivalka

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs

class ShareGridTest {
	private val itemCount = shots.size
	private val aspectRatio = 9f / 16f
	private val cellWidth = 20f
	private val cellHeight = 1.5f
	private val columnGap = 1.5f
	private val margin = 1.5f

	private fun grid(count: Int = itemCount) = shareGrid(count, cellWidth, cellHeight, columnGap, margin, aspectRatio)

	private fun contentAspect(columns: Int, rows: Int) =
		(2 * margin + columns * cellWidth + (columns - 1) * columnGap) / (2 * margin + rows * cellHeight)

	@Test
	fun canvasIsExactlyNineBySixteen() {
		val grid = grid()
		assertEquals(aspectRatio, grid.width / grid.height, 1e-5f)
	}

	@Test
	fun picksColumnCountClosestToTargetAspect() {
		val grid = grid()
		val chosen = abs(contentAspect(grid.columns, grid.rows) - aspectRatio)
		for (columns in 1..itemCount) {
			val rows = (itemCount + columns - 1) / columns
			assertTrue("columns=$columns", chosen <= abs(contentAspect(columns, rows) - aspectRatio) + 1e-6f)
		}
	}

	@Test
	fun everyItemFitsWithoutEmptyColumns() {
		val grid = grid()
		assertTrue(grid.columns * grid.rows >= itemCount)
		assertTrue((grid.columns - 1) * grid.rows < itemCount)
	}

	@Test
	fun contentIsCenteredInsideCanvas() {
		val grid = grid()
		val contentWidth = grid.columns * cellWidth + (grid.columns - 1) * columnGap
		val contentHeight = grid.rows * cellHeight
		assertEquals(grid.width - contentWidth, 2 * grid.contentLeft, 1e-3f)
		assertEquals(grid.height - contentHeight, 2 * grid.contentTop, 1e-3f)
		assertTrue(grid.contentLeft >= margin - 1e-4f)
		assertTrue(grid.contentTop >= margin - 1e-4f)
	}

	@Test
	fun cellsFlowTopToBottomThenLeftToRight() {
		val grid = grid()
		assertEquals(grid.contentLeft, grid.cellLeft(0))
		assertEquals(grid.contentTop, grid.cellTop(0))
		assertEquals(grid.contentLeft, grid.cellLeft(1))
		assertEquals(grid.contentTop + cellHeight, grid.cellTop(1))
		assertEquals(grid.contentLeft + cellWidth + columnGap, grid.cellLeft(grid.rows))
		assertEquals(grid.contentTop, grid.cellTop(grid.rows))
	}

	@Test
	fun singleItemIsCentered() {
		val grid = grid(count = 1)
		assertEquals(1, grid.columns)
		assertEquals(1, grid.rows)
		assertEquals(aspectRatio, grid.width / grid.height, 1e-5f)
		assertEquals(grid.width - cellWidth, 2 * grid.contentLeft, 1e-3f)
		assertEquals(grid.height - cellHeight, 2 * grid.contentTop, 1e-3f)
	}
}
