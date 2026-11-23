package dev.hloth.espivalka.ui

import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.text.input.rememberTextFieldState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import dev.hloth.espivalka.RatingStore

@Composable
fun EspivalkaApp(ratingStore: RatingStore) {
	val query = rememberTextFieldState()
	val listState = rememberLazyListState()
	var selectedShot by rememberSaveable { mutableStateOf<String?>(null) }
	val shot = selectedShot
	if (shot == null) {
		ShotListScreen(query, listState, ratingStore.ratings, onShotClick = { selectedShot = it })
	} else {
		RatingScreen(
			shot = shot,
			savedRating = ratingStore.ratings[shot],
			onBack = { selectedShot = null },
			onSave = { rating ->
				ratingStore.rate(shot, rating)
				selectedShot = null
			},
		)
	}
}
