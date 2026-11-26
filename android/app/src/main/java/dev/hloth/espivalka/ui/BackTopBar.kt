package dev.hloth.espivalka.ui

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import dev.hloth.espivalka.R

@Composable
fun BackTopBar(title: String, onBack: () -> Unit) {
	TopAppBar(
		title = { GlowText(title) },
		navigationIcon = {
			IconButton(onClick = onBack) {
				Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.back))
			}
		},
	)
}
