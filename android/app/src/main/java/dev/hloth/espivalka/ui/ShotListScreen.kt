package dev.hloth.espivalka.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.input.TextFieldState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.ListItem
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SearchBarDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.rememberSearchBarState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import dev.hloth.espivalka.R
import dev.hloth.espivalka.filterShots
import dev.hloth.espivalka.shots
import dev.hloth.espivalka.ui.theme.BackgroundColor
import dev.hloth.espivalka.ui.theme.ComicSans
import dev.hloth.espivalka.ui.theme.StarColor
import dev.hloth.espivalka.ui.theme.TextColor
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.launch
import java.io.IOException

private const val ShareItemKey = "share"

@Composable
fun ShotListScreen(
	query: TextFieldState,
	listState: LazyListState,
	ratings: Map<String, Int>,
	onShotClick: (String) -> Unit,
) {
	val results by remember(query) { derivedStateOf { filterShots(query.text.toString()) } }
	val context = LocalContext.current
	val scope = rememberCoroutineScope()
	var sharing by remember { mutableStateOf(false) }
	LaunchedEffect(query, listState) {
		snapshotFlow { query.text.toString() }.drop(1).collect { listState.scrollToItem(0) }
	}
	Scaffold(topBar = { SearchTopBar(query, ratings.size) }) { padding ->
		LazyColumn(
			modifier = Modifier
				.fillMaxSize()
				.consumeWindowInsets(padding)
				.imePadding(),
			state = listState,
			contentPadding = padding,
		) {
			items(results, key = { it }) { shot ->
				ShotRow(shot, ratings[shot], onClick = { onShotClick(shot) })
				HorizontalDivider()
			}
			item(key = ShareItemKey) {
				ShareButton(
					enabled = !sharing,
					onClick = {
						sharing = true
						scope.launch {
							try {
								context.shareImage(exportShareImage(context, ratings.toMap()))
							} catch (_: IOException) {
							} finally {
								sharing = false
							}
						}
					},
				)
			}
		}
	}
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SearchTopBar(query: TextFieldState, ratedCount: Int) {
	val searchBarState = rememberSearchBarState()
	val scope = rememberCoroutineScope()
	val progressLabel = stringResource(R.string.progress_label)
	val progressValue = stringResource(R.string.progress_value, ratedCount, shots.size)
	Surface {
		Column {
			Surface(
				modifier = Modifier
					.windowInsetsPadding(SearchBarDefaults.windowInsets)
					.padding(horizontal = 16.dp, vertical = 8.dp),
				shape = SearchBarDefaults.inputFieldShape,
				color = SearchBarDefaults.colors().containerColor,
			) {
				SearchBarDefaults.InputField(
					textFieldState = query,
					searchBarState = searchBarState,
					onSearch = { scope.launch { searchBarState.animateToCollapsed() } },
					modifier = Modifier.fillMaxWidth(),
					placeholder = { Text(stringResource(R.string.search)) },
					leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },
					keyboardOptions = KeyboardOptions(autoCorrectEnabled = false, imeAction = ImeAction.Search),
					colors = SearchBarDefaults.inputFieldColors(cursorColor = TextColor),
				)
			}
			LinearProgressIndicator(
				progress = { ratedCount.toFloat() / shots.size },
				modifier = Modifier
					.fillMaxWidth()
					.height(3.dp)
					.semantics {
						contentDescription = progressLabel
						stateDescription = progressValue
					},
				color = Color.White,
				trackColor = BackgroundColor,
				strokeCap = StrokeCap.Butt,
				gapSize = 0.dp,
				drawStopIndicator = {},
			)
		}
	}
}

@Composable
private fun ShotRow(shot: String, rating: Int?, onClick: () -> Unit) {
	ListItem(
		onClick = onClick,
		trailingContent = rating?.let { { RatingStars(it) } },
	) {
		GlowText(shot.uppercase(), style = LocalTextStyle.current.copy(fontFamily = ComicSans))
	}
}

@Composable
private fun RatingStars(rating: Int) {
	val description = pluralStringResource(R.plurals.stars, rating, rating)
	Row(Modifier.semantics { contentDescription = description }) {
		repeat(rating) {
			Icon(FilledStar, contentDescription = null, modifier = Modifier.size(18.dp), tint = StarColor)
		}
	}
}

@Composable
private fun ShareButton(enabled: Boolean, onClick: () -> Unit) {
	Box(
		modifier = Modifier
			.fillMaxWidth()
			.padding(vertical = 24.dp),
		contentAlignment = Alignment.Center,
	) {
		Button(onClick = onClick, enabled = enabled, contentPadding = ButtonDefaults.ButtonWithIconContentPadding) {
			Icon(Icons.Filled.Share, contentDescription = null, modifier = Modifier.size(ButtonDefaults.IconSize))
			Spacer(Modifier.size(ButtonDefaults.IconSpacing))
			Text(stringResource(R.string.share))
		}
	}
}
