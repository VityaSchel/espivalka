#!/bin/bash
set -euo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
source "$(dirname "${BASH_SOURCE[0]}")/android-pins.sh"

readonly gradle_home=$android_root-gradle
readonly android_jar_sha256=d827b4304f0144ad6332f7a236ccf0659f6bd845f5ba739db475d9e822272c85
readonly gradle_wrapper_jar_sha256=621008afc4f5d59357fcf06ffa644dd5aade5e091bdc363742710445f73cdaf8
readonly r8_mapping_in_bundle=BUNDLE-METADATA/com.android.tools.build.obfuscation/proguard.map
[ $# -le 1 ] || { echo "usage: android-build.sh [commit]" >&2; exit 2; }
repo=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)
commit=$(git -C "$repo" rev-parse --verify "${1:-HEAD}^{commit}")
epoch=$(git -C "$repo" log -1 --no-show-signature --format=%ct "$commit")
readonly repo commit epoch
: "${JAVA_HOME:?set JAVA_HOME to a JDK $java_major}"
: "${ANDROID_HOME:?set ANDROID_HOME to the Android SDK}"

hermetic() {
	env -i PATH="$PATH" HOME="$HOME" GRADLE_USER_HOME="$gradle_home" JAVA_HOME="$JAVA_HOME" ANDROID_HOME="$ANDROID_HOME" \
		TZ=UTC LC_ALL=C SOURCE_DATE_EPOCH="$epoch" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ATTR_NOSYSTEM=1 "$@"
}

found=$(hermetic "$JAVA_HOME/bin/java" -XshowSettings:properties -version 2>&1 | awk -F' = ' '/java.specification.version/ { print $2 }' || true)
readonly found
if [ "$found" != "$java_major" ]; then
	echo "JDK $java_major is required, $JAVA_HOME has ${found:-none}" >&2
	exit 1
fi

if ! has_sha256 "$android_jar_sha256" "$ANDROID_HOME/platforms/android-$android_platform/android.jar"; then
	echo "platform android-$android_platform revision 1 is required in $ANDROID_HOME" >&2
	exit 1
fi

mkdir "$android_root.lock" 2>/dev/null || { echo "$android_root is in use by another android-build.sh, or remove $android_root.lock" >&2; exit 1; }
trap 'rmdir "$android_root.lock"' EXIT

mkdir -p "$gradle_home"
if [ -L "$gradle_home" ] || [ ! -O "$gradle_home" ]; then
	echo "$gradle_home is not a directory of yours" >&2
	exit 1
fi
chmod 700 "$gradle_home"
mkdir -p "$gradle_home/caches" "$gradle_home/wrapper"
find "$gradle_home" -mindepth 1 -maxdepth 1 ! -name caches ! -name wrapper -exec rm -rf {} +
find "$gradle_home/caches" -mindepth 1 -maxdepth 1 ! -name modules-2 -exec rm -rf {} +

readonly project=$android_root/src/android out=$android_root/out
rm -rf "$android_root"
mkdir -m 700 "$android_root"
mkdir "$android_root/src" "$out"
hermetic git clone -q --bare --shared --template= "$repo" "$android_root/git"
hermetic git -C "$android_root/git" -c core.attributesFile=/dev/null archive "$commit" | tar -x -C "$android_root/src"

if ! has_sha256 "$gradle_wrapper_jar_sha256" "$project/gradle/wrapper/gradle-wrapper.jar"; then
	echo "the gradle-wrapper.jar of $commit is not the one Gradle publishes" >&2
	exit 1
fi

(cd "$project" && hermetic ./gradlew --no-daemon --no-build-cache --no-watch-fs --dependency-verification=strict --console=plain \
	-Dorg.gradle.java.installations.auto-detect=false -Dorg.gradle.java.installations.auto-download=false \
	-Pandroid.builder.sdkDownload=false -Pkotlin.compiler.execution.strategy=in-process \
	assembleRelease bundleRelease) > "$android_root/build.log" 2>&1 ||
	{ echo "the build failed, see $android_root/build.log" >&2; exit 1; }

version=$(sed -n 's/^[[:space:]]*versionName = "\(.*\)"$/\1/p' "$project/app/build.gradle.kts")
readonly unsigned=$out/espivalka-v$version-android-unsigned
cp "$project/app/build/outputs/apk/release/app-release-unsigned.apk" "$unsigned.apk"
cp "$project/app/build/outputs/bundle/release/app-release.aab" "$unsigned.aab"
hermetic zip -q -d "$unsigned.aab" "$r8_mapping_in_bundle"
echo "$commit" > "$android_root/commit"
(cd "$out" && sha256 -- *)
echo "built $commit with JDK $found into $out"
