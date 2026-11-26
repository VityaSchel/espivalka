package dev.hloth.espivalka

import org.junit.Assert.assertEquals
import org.junit.Test

class NavigationTest {
	private val rating = Screen.Rating(shots.first())

	@Test
	fun everyScreenSurvivesItsRoute() {
		val screens = listOf(Screen.ShotList, Screen.Random) + shots.map(Screen::Rating)
		screens.forEach { assertEquals(it, screenOf(it.route)) }
	}

	@Test
	fun screensOpenOnlyFromTheTopScreen() {
		val backStack = mutableListOf<Screen>(Screen.ShotList)
		backStack.open(rating, from = Screen.ShotList)
		backStack.open(Screen.Random, from = Screen.ShotList)
		assertEquals(listOf(Screen.ShotList, rating), backStack)
	}

	@Test
	fun closingTwiceLeavesTheShotList() {
		val backStack = mutableListOf(Screen.ShotList, rating)
		backStack.close(rating)
		backStack.close(rating)
		assertEquals(listOf(Screen.ShotList), backStack)
	}

	@Test
	fun randomIsReplacedByTheRatingOfThePickedShot() {
		val backStack = mutableListOf(Screen.ShotList, Screen.Random)
		backStack.replace(Screen.Random, rating)
		backStack.replace(Screen.Random, Screen.Rating(shots.last()))
		assertEquals(listOf(Screen.ShotList, rating), backStack)
	}
}
