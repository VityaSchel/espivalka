#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/android-pins.sh"

readonly usage="usage: ANDROID_APK_KEYSTORE=<keystore> ANDROID_APK_KEY_ALIAS=<alias> ANDROID_PLAY_UPLOAD_KEYSTORE=<keystore> ANDROID_PLAY_UPLOAD_KEY_ALIAS=<alias> android-sign.sh [directory of the unsigned apk and aab]"
[ $# -le 1 ] || { echo "$usage" >&2; exit 2; }
for variable in ANDROID_APK_KEYSTORE ANDROID_APK_KEY_ALIAS ANDROID_PLAY_UPLOAD_KEYSTORE ANDROID_PLAY_UPLOAD_KEY_ALIAS; do
	[ -n "${!variable:-}" ] || { echo "$usage" >&2; exit 2; }
done
: "${JAVA_HOME:?set JAVA_HOME to a JDK}" "${ANDROID_HOME:?set ANDROID_HOME to the Android SDK}"
readonly dir=${1:-$android_root/out}
unsigned=$(unsigned_build_in "$dir")
readonly unsigned signed=${unsigned%-unsigned}
[ -f "$unsigned.apk" ] && [ -f "$unsigned.aab" ] || { echo "no single unsigned APK and AAB in $dir: run android-build.sh first" >&2; exit 1; }

refuse() {
	echo "$1" >&2
	exit 1
}

apk_public_key() {
	apksigner verify -v --min-sdk-version "$android_min_sdk" --print-certs "$1" | sed -n 's/^Signer #1 public key SHA-256 digest: //p'
}

aab_public_key() {
	keytool -printcert -rfc -jarfile "$1" | openssl x509 -noout -pubkey | openssl pkey -pubin -outform DER | sha256 | cut -d ' ' -f 1
}

report() {
	echo "$1 certificate SHA-256: $3"
	[ -f "$(certificate_pin "$2")" ] || echo "  not pinned yet: write it to android/$2-certificate.sha256 and commit it"
}

trap 'rm -f "$signed.apk" "$signed.aab"' EXIT
apksigner sign --ks "$ANDROID_APK_KEYSTORE" --ks-key-alias "$ANDROID_APK_KEY_ALIAS" --alignment-preserved \
	--v1-signing-enabled false --v2-signing-enabled true --v3-signing-enabled true --v4-signing-enabled false \
	--out "$signed.apk" "$unsigned.apk"
jarsigner -keystore "$ANDROID_PLAY_UPLOAD_KEYSTORE" -sigalg SHA256withRSA -digestalg SHA-256 \
	-signedjar "$signed.aab" "$unsigned.aab" "$ANDROID_PLAY_UPLOAD_KEY_ALIAS" > /dev/null
jarsigner -verify "$signed.aab" | grep -q '^jar verified\.$' || refuse "the signed AAB does not verify"

apk_public_key=$(apk_public_key "$signed.apk")
aab_public_key=$(aab_public_key "$signed.aab")
apk_certificate=$(apk_certificates "$signed.apk")
aab_certificate=$(aab_certificates "$signed.aab")
readonly apk_public_key aab_public_key apk_certificate aab_certificate
for digest in "$apk_public_key" "$aab_public_key" "$apk_certificate" "$aab_certificate"; do
	is_sha256_digest "$digest" || refuse "the signed APK and AAB do not each have exactly one readable signer"
done
[ "$apk_public_key" != "$aab_public_key" ] || refuse "the APK release key and the Play upload key must differ"
matches_pin release "$apk_certificate" || refuse "the APK release key is not the one pinned in android/release-certificate.sha256"
matches_pin upload "$aab_certificate" || refuse "the Play upload key is not the one pinned in android/upload-certificate.sha256"
trap - EXIT

sha256 "$signed.apk" "$signed.aab"
report "APK release" release "$apk_certificate"
report "Play upload" upload "$aab_certificate"
