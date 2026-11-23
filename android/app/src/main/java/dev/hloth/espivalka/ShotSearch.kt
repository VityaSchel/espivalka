package dev.hloth.espivalka

import java.text.Normalizer
import java.util.Locale

private val combiningMarks = Regex("\\p{Mn}+")

fun String.folded(): String =
	Normalizer.normalize(this, Normalizer.Form.NFD).replace(combiningMarks, "").lowercase(Locale.ROOT)

private val foldedShots = shots.associateWith { it.folded() }

fun filterShots(query: String): List<String> {
	val needle = query.trim().folded()
	if (needle.isEmpty()) return shots
	return foldedShots.filterValues { needle in it }.keys.toList()
}
