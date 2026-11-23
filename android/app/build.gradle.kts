plugins {
	alias(libs.plugins.android.application)
	alias(libs.plugins.kotlin.compose)
}

android {
	namespace = "dev.hloth.espivalka"
	compileSdk {
		version = release(37) {
			minorApiLevel = 1
		}
	}

	defaultConfig {
		applicationId = "dev.hloth.espivalka"
		minSdk = 31
		targetSdk = 37
		versionCode = 1
		versionName = "1.0"
	}

	buildTypes {
		release {
			optimization {
				enable = true
			}
			vcsInfo.include = false
		}
	}
	dependenciesInfo {
		includeInApk = false
		includeInBundle = false
	}
	androidResources {
		localeFilters += "en"
	}
	packaging {
		jniLibs.keepDebugSymbols += "**/libandroidx.graphics.path.so"
	}
	compileOptions {
		sourceCompatibility = JavaVersion.VERSION_11
		targetCompatibility = JavaVersion.VERSION_11
	}
	buildFeatures {
		compose = true
	}
}

dependencies {
	implementation(platform(libs.androidx.compose.bom))
	implementation(libs.androidx.activity.compose)
	implementation(libs.androidx.compose.material3)
	implementation(libs.androidx.compose.material.icons.core)
	implementation(libs.androidx.compose.ui)
	implementation(libs.androidx.core.ktx)
	testImplementation(libs.junit)
}
