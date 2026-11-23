package dev.hloth.espivalka.ui

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Star
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.VectorPath
import androidx.compose.ui.graphics.vector.toPath

private val starPathData = Icons.Filled.Star.root.filterIsInstance<VectorPath>().single().pathData
private val starPath = starPathData.toPath()

val OutlinedStar: ImageVector = with(Icons.Filled.Star) {
	ImageVector.Builder(
		name = "OutlinedStar",
		defaultWidth = defaultWidth,
		defaultHeight = defaultHeight,
		viewportWidth = viewportWidth,
		viewportHeight = viewportHeight,
	).addGroup(clipPathData = starPathData).addPath(
		pathData = starPathData,
		stroke = SolidColor(Color.Black),
		strokeLineWidth = 4f,
		strokeLineJoin = StrokeJoin.Round,
	).build()
}

fun DrawScope.drawStar(topLeft: Offset, size: Float, color: Color) {
	val scale = size / Icons.Filled.Star.viewportWidth
	withTransform({
		translate(topLeft.x, topLeft.y)
		scale(scale, scale, Offset.Zero)
	}) {
		drawPath(starPath, color)
	}
}
