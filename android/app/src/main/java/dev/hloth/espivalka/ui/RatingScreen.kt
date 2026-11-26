package dev.hloth.espivalka.ui

import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.drag
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import dev.hloth.espivalka.MaxRating
import dev.hloth.espivalka.R
import dev.hloth.espivalka.ui.theme.StarColor
import dev.hloth.espivalka.ui.theme.TextColor
import kotlin.math.ceil

@Composable
fun RatingScreen(shot: String, savedRating: Int?, onBack: () -> Unit, onSave: (Int) -> Unit) {
	var rating by rememberSaveable { mutableIntStateOf(savedRating ?: 0) }
	Scaffold(
		topBar = {
			TopAppBar(
				title = { GlowText(shot) },
				navigationIcon = {
					IconButton(onClick = onBack) {
						Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.back))
					}
				},
			)
		},
	) { padding ->
		Column(
			modifier = Modifier
				.fillMaxSize()
				.padding(padding),
			horizontalAlignment = Alignment.CenterHorizontally,
		) {
			Spacer(Modifier.weight(1f))
			RatingBar(rating, onRatingChange = { rating = it })
			Box(Modifier.weight(1f)) {
				Button(
					onClick = { onSave(rating) },
					modifier = Modifier.padding(top = 32.dp),
					enabled = rating > 0,
				) {
					Text(stringResource(R.string.save))
				}
			}
		}
	}
}

@Composable
private fun RatingBar(rating: Int, onRatingChange: (Int) -> Unit) {
	val currentOnRatingChange by rememberUpdatedState(onRatingChange)
	val layoutDirection = LocalLayoutDirection.current
	Row(
		Modifier
			.selectableGroup()
			.pointerInput(layoutDirection) {
				fun rateAt(x: Float) {
					val fromStart = if (layoutDirection == LayoutDirection.Rtl) size.width - x else x
					val star = ceil(fromStart / size.width * MaxRating).toInt().coerceIn(1, MaxRating)
					currentOnRatingChange(star)
				}
				awaitEachGesture {
					val down = awaitFirstDown()
					rateAt(down.position.x)
					drag(down.id) { change ->
						rateAt(change.position.x)
						change.consume()
					}
				}
			},
	) {
		for (star in 1..MaxRating) {
			val filled = star <= rating
			Icon(
				imageVector = if (filled) FilledStar else OutlinedStar,
				contentDescription = pluralStringResource(R.plurals.stars, star, star),
				modifier = Modifier
					.size(48.dp)
					.semantics {
						role = Role.RadioButton
						selected = star == rating
						onClick {
							currentOnRatingChange(star)
							true
						}
					},
				tint = if (filled) StarColor else TextColor,
			)
		}
	}
}
