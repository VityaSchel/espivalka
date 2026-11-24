package dev.hloth.espivalka.ui

import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.net.Uri
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Canvas
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.ImageBitmapConfig
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.graphics.drawscope.CanvasDrawScope
import androidx.compose.ui.graphics.drawscope.Fill
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.createFontFamilyResolver
import androidx.compose.ui.text.intl.LocaleList
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import dev.hloth.espivalka.MaxRating
import dev.hloth.espivalka.shareGrid
import dev.hloth.espivalka.shots
import dev.hloth.espivalka.ui.theme.BackgroundColor
import dev.hloth.espivalka.ui.theme.ComicSans
import dev.hloth.espivalka.ui.theme.StarColor
import dev.hloth.espivalka.ui.theme.TextColor
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

private const val ImageWidth = 2160
private const val ImageHeight = 3840
private const val ImageName = "Espivalka.png"
private const val ImageDirectory = "shared"
private const val ReferenceFontSize = 100f
private const val Columns = 6
private const val NameStarsGap = 0.5f
private const val StarSize = 1f
private const val ColumnGap = 1.5f
private const val Margin = 1.5f

suspend fun exportShareImage(context: Context, ratings: Map<String, Int>): Uri = withContext(Dispatchers.Default) {
	val file = File(File(context.cacheDir, ImageDirectory), ImageName)
	val bitmap = renderShareImage(context, ratings)
	try {
		file.parentFile?.mkdirs()
		file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
	} finally {
		bitmap.recycle()
	}
	FileProvider.getUriForFile(context, "${context.packageName}.files", file)
}

fun Context.shareImage(uri: Uri) {
	val send = Intent(Intent.ACTION_SEND)
		.setType("image/png")
		.putExtra(Intent.EXTRA_STREAM, uri)
		.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
	send.clipData = ClipData.newUri(contentResolver, ImageName, uri)
	startActivity(Intent.createChooser(send, null))
}

private fun renderShareImage(context: Context, ratings: Map<String, Int>): Bitmap {
	val density = Density(1f)
	val measurer = TextMeasurer(createFontFamilyResolver(context), LocaleList("en"), density, LayoutDirection.Ltr)
	val names = shots.map { it.uppercase() }
	val referenceStyle = TextStyle(color = TextColor, fontFamily = ComicSans, fontSize = ReferenceFontSize.sp)
	val grid = shareGrid(
		itemWidths = names.map {
			measurer.measure(it, referenceStyle).size.width / ReferenceFontSize + NameStarsGap + MaxRating * StarSize
		},
		columns = Columns,
		columnGap = ColumnGap,
		margin = Margin,
		aspectRatio = ImageWidth.toFloat() / ImageHeight,
	)
	val em = ImageWidth / grid.width
	val starSize = StarSize * em
	val style = referenceStyle.copy(fontSize = em.sp)
	val image = ImageBitmap(ImageWidth, ImageHeight, ImageBitmapConfig.Argb8888, hasAlpha = false)
	val size = Size(ImageWidth.toFloat(), ImageHeight.toFloat())
	CanvasDrawScope().draw(density, LayoutDirection.Ltr, Canvas(image), size) {
		drawRect(BackgroundColor)
		names.forEachIndexed { index, name ->
			val left = grid.cellLeft(index) * em
			val right = grid.cellRight(index) * em
			val centerY = (grid.cellTop(index) + grid.rowHeight / 2) * em
			val layout = measurer.measure(name, style)
			val textTopLeft = Offset(left, centerY - layout.size.height / 2f)
			drawGlow(layout, textTopLeft)
			drawText(layout, topLeft = textTopLeft, shadow = Shadow.None, drawStyle = Fill)
			repeat(ratings[shots[index]] ?: 0) { star ->
				drawStar(Offset(right - (star + 1) * starSize, centerY - starSize / 2), starSize, StarColor)
			}
		}
	}
	return image.asAndroidBitmap()
}
