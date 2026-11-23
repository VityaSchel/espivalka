readonly java_major=21
readonly android_platform=37.1
readonly android_build_tools=36.0.0
readonly android_min_sdk=31
readonly android_root=/tmp/espivalka-android

sha256() {
	if command -v sha256sum >/dev/null; then sha256sum "$@"; else shasum -a 256 "$@"; fi
}

has_sha256() {
	echo "$1  $2" | sha256 -c - >/dev/null 2>&1
}

retry() {
	"$@" || "$@" || "$@"
}

is_sha256_digest() {
	[[ $1 =~ ^[0-9a-f]{64}$ ]]
}

debian_java_home() {
	echo "/usr/lib/jvm/java-$java_major-openjdk-$(dpkg --print-architecture)"
}

apksigner() {
	"$ANDROID_HOME/build-tools/$android_build_tools/apksigner" "$@"
}

jarsigner() {
	"$JAVA_HOME/bin/jarsigner" "$@"
}

keytool() {
	"$JAVA_HOME/bin/keytool" "$@"
}

unsigned_build_in() {
	local apk
	apk=$(echo "$1"/espivalka-v*-android-unsigned.apk)
	echo "${apk%.apk}"
}

apk_certificates() {
	apksigner verify --min-sdk-version "$android_min_sdk" --print-certs "$1" | sed -n 's/^Signer #[0-9]* certificate SHA-256 digest: //p'
}

aab_certificates() {
	keytool -printcert -jarfile "$1" | awk '/^Signer #/ { signer = 1 } signer && $1 == "SHA256:" { gsub(":", "", $2); print tolower($2); signer = 0 }'
}

certificate_pin() {
	echo "$(dirname "${BASH_SOURCE[0]}")/../android/$1-certificate.sha256"
}

matches_pin() {
	local pin
	pin=$(certificate_pin "$1")
	[ ! -f "$pin" ] || [ "$2" = "$(tr -d '[:space:]' < "$pin")" ]
}
