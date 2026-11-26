package dev.hloth.espivalka.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import dev.hloth.espivalka.R

val BackgroundColor = Color(0xFF02000A)
val TextColor = Color(0xFF13C0FF)
val GlowColor = Color(0xFF3300FF)
val StarColor = Color(0xFFFFA100)
val AccentColor = Color(0xFF6400FD)

private val DividerColor = GlowColor.copy(alpha = 0.4f).compositeOver(BackgroundColor)
private val SearchFieldColor = GlowColor.copy(alpha = 0.2f).compositeOver(BackgroundColor)
private val DarkBlueColor = TextColor.copy(alpha = 0.35f).compositeOver(BackgroundColor)

val WheelPalette = listOf(AccentColor, TextColor, GlowColor, DarkBlueColor)

val ComicSans = FontFamily(Font(R.font.comic_sans_ms))

private val colorScheme = darkColorScheme(
	primary = AccentColor,
	onPrimary = TextColor,
	background = BackgroundColor,
	onBackground = TextColor,
	surface = BackgroundColor,
	onSurface = TextColor,
	onSurfaceVariant = TextColor.copy(alpha = 0.7f),
	surfaceContainerHigh = SearchFieldColor,
	outlineVariant = DividerColor,
)

@Composable
fun EspivalkaTheme(content: @Composable () -> Unit) {
	MaterialTheme(colorScheme = colorScheme, content = content)
}
