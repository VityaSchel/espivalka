package dev.hloth.espivalka

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.random.Random

class WheelTest {
	private val sliceCounts = listOf(1, 2, 3, 4, 5, 7, 9, 64, 629)
	private val frameSeconds = 0.001f

	private fun spins(sliceCount: Int) = Random(sliceCount).let { random -> List(200) { randomSpin(sliceCount, random) } }

	private fun times(from: Float, to: Float) = generateSequence(from) { it + frameSeconds }.takeWhile { it <= to }

	@Test
	fun wheelHoldsOnlyUnratedShots() {
		val ratings = shots.filterIndexed { index, _ -> index % 3 == 0 }.associateWith { 4 }
		assertEquals(shots.filterNot(ratings::containsKey).toSet(), wheelShots(ratings, Random(1)).toSet())
		assertEquals(shots.size - ratings.size, wheelShots(ratings, Random(1)).size)
	}

	@Test
	fun wheelKeepsTheLastUnratedShot() {
		val ratings = shots.drop(1).associateWith { 2 }
		assertEquals(listOf(shots.first()), wheelShots(ratings, Random(1)))
	}

	@Test
	fun wheelHoldsAllShotsOnceEverythingIsRated() {
		val ratings = shots.associateWith { 5 }
		assertEquals(shots.toSet(), wheelShots(ratings, Random(1)).toSet())
		assertEquals(shots.size, wheelShots(ratings, Random(1)).size)
	}

	@Test
	fun wheelOrderComesFromTheRandomSource() {
		assertEquals(wheelShots(emptyMap(), Random(7)), wheelShots(emptyMap(), Random(7)))
		assertNotEquals(wheelShots(emptyMap(), Random(7)), wheelShots(emptyMap(), Random(8)))
		assertNotEquals(shots, wheelShots(emptyMap(), Random(7)))
	}

	@Test
	fun neighboringSlicesNeverShareAColor() {
		val palette = listOf(0, 1, 2, 3)
		(2..40).plus(shots.size).forEach { sliceCount ->
			val colors = wheelColors(sliceCount, palette)
			colors.indices.forEach { slice ->
				assertNotEquals("$sliceCount slices, slice $slice", colors[slice], colors[(slice + 1) % sliceCount])
			}
		}
	}

	@Test
	fun singleSliceGetsOneColor() {
		assertEquals(listOf("a"), wheelColors(1, listOf("a", "b", "c", "d")))
	}

	@Test
	fun pointerReadsTheSliceAtTheTop() {
		assertEquals(0, sliceAtPointer(0f, 4))
		assertEquals(0, sliceAtPointer(-10f, 4))
		assertEquals(3, sliceAtPointer(10f, 4))
		assertEquals(2, sliceAtPointer(100f, 4))
		assertEquals(1, sliceAtPointer(FullTurn * 5 + 200f, 4))
		assertEquals(0, sliceAtPointer(12345f, 1))
	}

	@Test
	fun finalRotationPointsAtTheChosenSlice() {
		sliceCounts.forEach { sliceCount ->
			listOf(0, sliceCount / 2, sliceCount - 1).forEach { slice ->
				listOf(0.1f, 0.5f, 0.9f).forEach { offset ->
					val rotation = finalRotation(slice, offset, sliceCount, extraTurns = 4)
					assertEquals("$sliceCount slices, slice $slice, offset $offset", slice, sliceAtPointer(rotation, sliceCount))
					assertTrue(rotation >= 4 * FullTurn && rotation < 5 * FullTurn)
				}
			}
		}
	}

	@Test
	fun winnersAreUniform() {
		val sliceCount = 7
		val draws = 70_000
		val random = Random(42)
		val counts = IntArray(sliceCount)
		repeat(draws) { counts[randomSpin(sliceCount, random).winner]++ }
		counts.forEach { assertEquals(draws / sliceCount.toDouble(), it.toDouble(), draws * 0.005) }
	}

	@Test
	fun spinLandsOnTheWinnerAfterSeveralTurns() {
		sliceCounts.forEach { sliceCount ->
			spins(sliceCount).forEach { spin ->
				assertEquals(spin.winner, sliceAtPointer(spin.finalRotation, sliceCount))
				assertTrue(spin.finalRotation >= 3 * FullTurn)
			}
		}
	}

	@Test
	fun spinTakesFiveToEightSeconds() {
		assertTrue(SpinSeconds in 5f..8f)
	}

	@Test
	fun spinStartsAtRestAndEndsExactlyOnTheFinalRotation() {
		spins(5).forEach { spin ->
			assertEquals(0f, spin.rotationAt(0f))
			assertEquals(spin.finalRotation, spin.rotationAt(SpinSeconds))
			assertEquals(spin.finalRotation, spin.rotationAt(SpinSeconds + 1))
		}
	}

	@Test
	fun spinAcceleratesThenCoastsToAStop() {
		val spin = randomSpin(629, Random(3))
		val coastEnd = SpinUpSeconds + CoastSeconds
		val speeds = times(0f, coastEnd).map { (spin.rotationAt(it + frameSeconds) - spin.rotationAt(it)) / frameSeconds }.toList()
		val spinUpFrames = (SpinUpSeconds / frameSeconds).toInt()
		val topSpeed = speeds.max()
		assertTrue(speeds.take(spinUpFrames - 1).zipWithNext().all { (before, after) -> after > before })
		assertTrue(speeds.drop(spinUpFrames + 1).zipWithNext().all { (before, after) -> after <= before + 1 })
		assertTrue(speeds.all { it >= -1 })
		assertTrue(topSpeed > FullTurn)
		assertEquals(topSpeed, speeds[spinUpFrames], topSpeed * 0.01f)
		assertEquals(spin.finalRotation + spin.overshoot, spin.rotationAt(coastEnd), 0.01f)
	}

	@Test
	fun spinMovesWithoutJumps() {
		sliceCounts.forEach { sliceCount ->
			spins(sliceCount).take(20).forEach { spin ->
				times(0f, SpinSeconds + frameSeconds).zipWithNext().forEach { (before, after) ->
					assertTrue(spin.rotationAt(after) - spin.rotationAt(before) < 5f)
				}
			}
		}
	}

	@Test
	fun settleSwingsWithoutLeavingTheWinningSlice() {
		sliceCounts.forEach { sliceCount ->
			spins(sliceCount).forEach { spin ->
				assertTrue(spin.overshoot > 0)
				times(SpinUpSeconds + CoastSeconds, SpinSeconds + frameSeconds).forEach { seconds ->
					assertEquals("$sliceCount slices at $seconds s", spin.winner, sliceAtPointer(spin.rotationAt(seconds), sliceCount))
				}
			}
		}
	}

	@Test
	fun settleSwingsBackPastTheFinalRotation() {
		val spin = randomSpin(3, Random(5))
		val settle = times(SpinUpSeconds + CoastSeconds, SpinSeconds).map(spin::rotationAt).toList()
		assertTrue(settle.max() > spin.finalRotation)
		assertTrue(settle.min() < spin.finalRotation)
		assertEquals(spin.finalRotation, settle.last(), spin.overshoot * 0.02f)
	}
}
