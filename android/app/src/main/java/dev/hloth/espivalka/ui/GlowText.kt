package dev.hloth.espivalka.ui

import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.style.TextOverflow
import dev.hloth.espivalka.ui.theme.GlowColor

private const val GlowStrokeWidth = 0.15f
private const val GlowBlurRadius = 0.5f

fun DrawScope.drawGlow(layout: TextLayoutResult, topLeft: Offset = Offset.Zero) {
	val fontSize = layout.layoutInput.style.fontSize.toPx()
	drawText(
		textLayoutResult = layout,
		color = GlowColor,
		topLeft = topLeft,
		shadow = Shadow(color = GlowColor, blurRadius = fontSize * GlowBlurRadius),
		drawStyle = Stroke(width = fontSize * GlowStrokeWidth, join = StrokeJoin.Round),
	)
}

@Composable
fun GlowText(text: String, modifier: Modifier = Modifier, style: TextStyle = LocalTextStyle.current) {
	var layout by remember { mutableStateOf<TextLayoutResult?>(null) }
	Text(
		text = text,
		modifier = modifier.drawBehind { layout?.let { drawGlow(it) } },
		style = style,
		maxLines = 1,
		overflow = TextOverflow.Ellipsis,
		onTextLayout = { layout = it },
	)
}
