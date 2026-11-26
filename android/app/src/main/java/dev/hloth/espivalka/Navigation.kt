package dev.hloth.espivalka

private const val ShotListRoute = "shots"
private const val RandomRoute = "random"
private const val RatingRoutePrefix = "rating/"

sealed interface Screen {
	data object ShotList : Screen
	data object Random : Screen
	data class Rating(val shot: String) : Screen
}

val Screen.route: String
	get() = when (this) {
		Screen.ShotList -> ShotListRoute
		Screen.Random -> RandomRoute
		is Screen.Rating -> RatingRoutePrefix + shot
	}

fun screenOf(route: String): Screen = when (route) {
	ShotListRoute -> Screen.ShotList
	RandomRoute -> Screen.Random
	else -> Screen.Rating(route.removePrefix(RatingRoutePrefix))
}

fun MutableList<Screen>.open(screen: Screen, from: Screen) {
	if (last() == from) add(screen)
}

fun MutableList<Screen>.close(screen: Screen) {
	if (last() == screen) removeAt(lastIndex)
}

fun MutableList<Screen>.replace(screen: Screen, replacement: Screen) {
	if (last() == screen) set(lastIndex, replacement)
}
