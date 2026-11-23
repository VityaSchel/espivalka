package dev.hloth.espivalka

import android.graphics.Color
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import dev.hloth.espivalka.ui.EspivalkaApp
import dev.hloth.espivalka.ui.theme.EspivalkaTheme

class MainActivity : ComponentActivity() {
	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		enableEdgeToEdge(
			statusBarStyle = SystemBarStyle.dark(Color.TRANSPARENT),
			navigationBarStyle = SystemBarStyle.dark(Color.TRANSPARENT),
		)
		val ratingStore = RatingStore(this)
		setContent {
			EspivalkaTheme {
				EspivalkaApp(ratingStore)
			}
		}
	}
}
