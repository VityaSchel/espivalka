package dev.hloth.espivalka

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ShotSearchTest {
	@Test
	fun foldingRemovesDiacriticsAndCase() {
		assertEquals("fenix barca canero el ultimo", "FÉNIX BARÇA CAÑERO EL ÚLTIMO".folded())
	}

	@Test
	fun emptyQueryReturnsAllShotsInOrder() {
		assertEquals(shots, filterShots(""))
		assertEquals(shots, filterShots("  "))
	}

	@Test
	fun diacriticFreeQueriesFindAccentedNames() {
		mapOf("fenix" to "FÉNIX", "barca" to "BARÇA", "canero" to "CAÑERO", "ultimo" to "EL ÚLTIMO").forEach { (query, name) ->
			assertTrue("$query should find $name", name in filterShots(query))
		}
	}

	@Test
	fun accentedQueriesFindAccentedNames() {
		assertTrue("FÉNIX" in filterShots("Fénix"))
	}

	@Test
	fun surroundingWhitespaceIsIgnored() {
		assertTrue("FÉNIX" in filterShots(" fenix "))
		assertTrue("3er. GRADO" in filterShots("3ER. grado "))
	}

	@Test
	fun resultsKeepOriginalOrderAndMatchSubstring() {
		val results = filterShots("ca")
		assertEquals(shots.filter { "ca" in it.folded() }, results)
		assertTrue(results.isNotEmpty())
	}

	@Test
	fun unmatchedQueryReturnsNothing() {
		assertTrue(filterShots("zzzzzz").isEmpty())
	}
}
