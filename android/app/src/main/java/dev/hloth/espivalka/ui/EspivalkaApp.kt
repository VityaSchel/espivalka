package dev.hloth.espivalka.ui

import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.AnimatedContentTransitionScope.SlideDirection
import androidx.compose.animation.core.FiniteAnimationSpec
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.VisibilityThreshold
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.text.input.rememberTextFieldState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.saveable.listSaver
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.snapshots.SnapshotStateList
import androidx.compose.runtime.toMutableStateList
import androidx.compose.ui.unit.IntOffset
import androidx.navigation3.runtime.entryProvider
import androidx.navigation3.ui.NavDisplay
import dev.hloth.espivalka.RatingStore
import dev.hloth.espivalka.Screen
import dev.hloth.espivalka.close
import dev.hloth.espivalka.open
import dev.hloth.espivalka.route
import dev.hloth.espivalka.screenOf

private val BackStackSaver = listSaver<SnapshotStateList<Screen>, String>(
	save = { backStack -> backStack.map(Screen::route) },
	restore = { routes -> routes.map(::screenOf).toMutableStateList() },
)

private val NavigationSlideSpec = spring(stiffness = Spring.StiffnessMediumLow, visibilityThreshold = IntOffset.VisibilityThreshold)
private val GestureSlideSpec = tween<IntOffset>(easing = LinearEasing)

@Composable
fun EspivalkaApp(ratingStore: RatingStore) {
	val query = rememberTextFieldState()
	val listState = rememberLazyListState()
	val backStack = rememberSaveable(saver = BackStackSaver) { mutableStateListOf<Screen>(Screen.ShotList) }
	NavDisplay(
		backStack = backStack,
		onBack = { backStack.removeLastOrNull() },
		transitionSpec = { slide(SlideDirection.Start, NavigationSlideSpec) },
		popTransitionSpec = { slide(SlideDirection.End, NavigationSlideSpec) },
		predictivePopTransitionSpec = { slide(SlideDirection.End, GestureSlideSpec) },
		entryProvider = entryProvider {
			entry<Screen.ShotList> { screen ->
				ShotListScreen(
					query = query,
					listState = listState,
					ratings = ratingStore.ratings,
					onShotClick = { shot -> backStack.open(Screen.Rating(shot), from = screen) },
				)
			}
			entry<Screen.Rating> { screen ->
				RatingScreen(
					shot = screen.shot,
					savedRating = ratingStore.ratings[screen.shot],
					onBack = { backStack.close(screen) },
					onSave = { rating ->
						ratingStore.rate(screen.shot, rating)
						backStack.close(screen)
					},
				)
			}
		},
	)
}

private fun AnimatedContentTransitionScope<*>.slide(towards: SlideDirection, animationSpec: FiniteAnimationSpec<IntOffset>) =
	slideIntoContainer(towards, animationSpec) togetherWith slideOutOfContainer(towards, animationSpec)
