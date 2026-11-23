package dev.hloth.espivalka.ui

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Star
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.VectorPath
import androidx.compose.ui.graphics.vector.toPath

val FilledStar: ImageVector = Icons.Rounded.Star

private val starPathData = FilledStar.root.filterIsInstance<VectorPath>().single().pathData
private val starPath = starPathData.toPath()

val OutlinedStar: ImageVector = with(FilledStar) {
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
	val scale = size / FilledStar.viewportWidth
	withTransform({
		translate(topLeft.x, topLeft.y)
		scale(scale, scale, Offset.Zero)
	}) {
		drawPath(starPath, color)
	}
}
