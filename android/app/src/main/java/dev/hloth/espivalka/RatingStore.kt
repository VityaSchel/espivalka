package dev.hloth.espivalka

import android.content.Context
import androidx.compose.runtime.mutableStateMapOf
import androidx.core.content.edit

const val MaxRating = 5

class RatingStore(context: Context) {
	private val preferences = context.getSharedPreferences("ratings", Context.MODE_PRIVATE)

	private val state = mutableStateMapOf<String, Int>().apply {
		val stored = preferences.all
		shots.forEach { shot ->
			(stored[shot] as? Int)?.takeIf { it in 1..MaxRating }?.let { put(shot, it) }
		}
	}

	val ratings: Map<String, Int> get() = state

	fun rate(shot: String, rating: Int) {
		state[shot] = rating
		preferences.edit { putInt(shot, rating) }
	}
}
