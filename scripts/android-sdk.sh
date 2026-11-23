#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/android-pins.sh"

[ $# -eq 1 ] || { echo "usage: android-sdk.sh <sdk directory>" >&2; exit 2; }
readonly sdk=$1
readonly cmdline_tools=$sdk/cmdline-tools/21.0
readonly cmdline_tools_zip=commandlinetools-linux-15641748_latest.zip
readonly cmdline_tools_zip_sha256=a66d5ef0238fc0162e9c1446602ce0dd41702d4dd7a94d2ce42d12b7f80baf7e
readonly packages=("platforms;android-$android_platform" "build-tools;$android_build_tools")

if [ "$(uname -s)" != Linux ]; then
	echo "this installs the Linux SDK; on macOS use Android Studio's SDK Manager" >&2
	exit 1
fi

java_home=$(debian_java_home)
readonly java_home
{ command -v curl && command -v unzip && command -v zip && command -v git && [ -x "$java_home/bin/javac" ]; } >/dev/null 2>&1 || {
	export DEBIAN_FRONTEND=noninteractive
	apt-get update -y
	apt-get install -y --no-install-recommends ca-certificates curl unzip zip git "openjdk-$java_major-jdk-headless"
}

if [ ! -x "$cmdline_tools/bin/sdkmanager" ]; then
	mkdir -p "$sdk/cmdline-tools"
	download=$(mktemp -d "$sdk/cmdline-tools/.download.XXXXXX")
	trap 'rm -rf "$download"' EXIT
	retry curl -fsSLo "$download/$cmdline_tools_zip" "https://dl.google.com/android/repository/$cmdline_tools_zip"
	has_sha256 "$cmdline_tools_zip_sha256" "$download/$cmdline_tools_zip" || { echo "$cmdline_tools_zip does not have its pinned SHA-256" >&2; exit 1; }
	unzip -q "$download/$cmdline_tools_zip" -d "$download"
	rm -rf "$cmdline_tools"
	mv "$download/cmdline-tools" "$cmdline_tools"
fi

export JAVA_HOME=$java_home
"$cmdline_tools/bin/sdkmanager" --sdk_root="$sdk" --licenses < <(yes) > /dev/null
retry "$cmdline_tools/bin/sdkmanager" --sdk_root="$sdk" --install "${packages[@]}" > /dev/null
