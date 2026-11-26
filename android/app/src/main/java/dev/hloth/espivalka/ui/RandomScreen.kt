package dev.hloth.espivalka.ui

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.EnterExitState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.AnimationVector1D
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.listSaver
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.navigation3.ui.LocalNavAnimatedContentScope
import dev.hloth.espivalka.R
import dev.hloth.espivalka.SpinSeconds
import dev.hloth.espivalka.WheelSpin
import dev.hloth.espivalka.randomSpin
import dev.hloth.espivalka.rotationAt
import dev.hloth.espivalka.sliceAngle
import dev.hloth.espivalka.sliceAtPointer
import dev.hloth.espivalka.wheelColors
import dev.hloth.espivalka.wheelShots
import dev.hloth.espivalka.ui.theme.BackgroundColor
import dev.hloth.espivalka.ui.theme.StarColor
import dev.hloth.espivalka.ui.theme.WheelPalette
import kotlinx.coroutines.flow.first
import java.security.SecureRandom
import kotlin.random.asKotlinRandom

private const val TopAngle = -90f
private const val MinSeparatedSliceAngle = 6f
private const val MillisPerSecond = 1000
private val PointerWidth = 28.dp
private val PointerHeight = 24.dp
private val NameHeight = 64.dp
private val SeparatorWidth = 2.dp
private val OverlayColor = Color.Black.copy(alpha = 0.65f)

private val secureRandom = SecureRandom().asKotlinRandom()

private val CandidatesSaver = listSaver<List<String>, String>(save = { it }, restore = { it })

private val SpinSaver = listSaver<WheelSpin, Any>(
	save = { listOf(it.winner, it.finalRotation, it.overshoot) },
	restore = { WheelSpin(winner = it[0] as Int, finalRotation = it[1] as Float, overshoot = it[2] as Float) },
)

private val ClockSaver = Saver<Animatable<Float, AnimationVector1D>, Float>(save = { it.value }, restore = { Animatable(it) })

@Composable
fun RandomScreen(ratings: Map<String, Int>, onBack: () -> Unit, onPicked: (String) -> Unit) {
	val candidates = rememberSaveable(saver = CandidatesSaver) { wheelShots(ratings, secureRandom) }
	val spin = rememberSaveable(saver = SpinSaver) { randomSpin(candidates.size, secureRandom) }
	val winner = candidates[spin.winner]
	val clock = rememberSaveable(saver = ClockSaver) { Animatable(0f) }
	val rotation = remember { { spin.rotationAt(clock.value) } }
	var landed by rememberSaveable { mutableStateOf(false) }
	val screenTransition = LocalNavAnimatedContentScope.current.transition
	val pickWinner = { onPicked(winner) }
	LaunchedEffect(Unit) {
		if (clock.value == 0f) {
			snapshotFlow { screenTransition.currentState }.first { it == EnterExitState.Visible }
		}
		val remainingMillis = ((SpinSeconds - clock.value) * MillisPerSecond).toInt()
		clock.animateTo(SpinSeconds, tween(remainingMillis, easing = LinearEasing))
		landed = true
	}
	BackHandler(enabled = landed, onBack = pickWinner)
	Box {
		Scaffold(topBar = { BackTopBar(stringResource(R.string.random), onBack) }) { padding ->
			Column(
				modifier = Modifier
					.fillMaxSize()
					.padding(padding)
					.padding(16.dp),
				verticalArrangement = Arrangement.Center,
				horizontalAlignment = Alignment.CenterHorizontally,
			) {
				PointedShot(candidates, rotation)
				Box(Modifier.weight(1f, fill = false), contentAlignment = Alignment.TopCenter) {
					Wheel(
						sliceCount = candidates.size,
						rotation = rotation,
						modifier = Modifier
							.padding(top = PointerHeight / 2)
							.aspectRatio(1f),
					)
					Pointer()
				}
			}
		}
		AnimatedVisibility(visible = landed, enter = fadeIn()) {
			WinnerOverlay(winner, onClick = pickWinner)
		}
	}
}

@Composable
private fun PointedShot(candidates: List<String>, rotation: () -> Float) {
	val shot by remember { derivedStateOf { candidates[sliceAtPointer(rotation(), candidates.size)] } }
	Box(
		modifier = Modifier
			.fillMaxWidth()
			.height(NameHeight),
		contentAlignment = Alignment.Center,
	) {
		ShotName(shot, MaterialTheme.typography.displaySmall)
	}
}

@Composable
private fun Wheel(sliceCount: Int, rotation: () -> Float, modifier: Modifier = Modifier) {
	val colors = remember(sliceCount) { wheelColors(sliceCount, WheelPalette) }
	Canvas(
		modifier.graphicsLayer {
			rotationZ = rotation()
			compositingStrategy = CompositingStrategy.Offscreen
		},
	) {
		val sweep = sliceAngle(sliceCount)
		colors.forEachIndexed { slice, color ->
			drawArc(color, startAngle = TopAngle + slice * sweep, sweepAngle = sweep, useCenter = true)
		}
		if (sweep >= MinSeparatedSliceAngle) {
			repeat(sliceCount) { slice ->
				rotate(slice * sweep) {
					drawLine(BackgroundColor, start = center, end = Offset(center.x, 0f), strokeWidth = SeparatorWidth.toPx())
				}
			}
		}
	}
}

@Composable
private fun Pointer() {
	Canvas(Modifier.size(PointerWidth, PointerHeight)) {
		val triangle = Path().apply {
			lineTo(size.width, 0f)
			lineTo(size.width / 2, size.height)
			close()
		}
		drawPath(triangle, StarColor)
	}
}

@Composable
private fun WinnerOverlay(shot: String, onClick: () -> Unit) {
	Box(
		modifier = Modifier
			.fillMaxSize()
			.background(OverlayColor)
			.clickable(
				interactionSource = null,
				indication = null,
				onClickLabel = stringResource(R.string.rate),
				onClick = onClick,
			)
			.safeDrawingPadding()
			.padding(24.dp),
		contentAlignment = Alignment.Center,
	) {
		ShotName(shot, MaterialTheme.typography.displayLarge)
	}
}
