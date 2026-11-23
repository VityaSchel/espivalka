package dev.hloth.espivalka

import org.junit.Assert.assertEquals
import org.junit.Test

class ShotsTest {
	@Test
	fun containsAllShots() {
		assertEquals(629, shots.size)
	}

	@Test
	fun namesAreUnique() {
		assertEquals(shots.size, shots.toSet().size)
	}

	@Test
	fun namesAreUniqueWhenUppercased() {
		assertEquals(shots.size, shots.map { it.uppercase() }.toSet().size)
	}
}
