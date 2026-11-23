#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/android-pins.sh"

[ $# -eq 1 ] || [ $# -eq 2 ] || { echo "usage: android-verify.sh <published apk> [<published aab>], after android-build.sh <commit>" >&2; exit 2; }
readonly published_apk=$1 published_aab=${2:-}
: "${JAVA_HOME:?set JAVA_HOME to a JDK}" "${ANDROID_HOME:?set ANDROID_HOME to the Android SDK}"
readonly jar_signature='META-INF/([^/]+\.(SF|RSA|DSA|EC)|MANIFEST\.MF)'
readonly apksigcopier_requirements=(
	"apksigcopier==1.1.1 --hash=sha256:0834bb7d6f3607bb0994cf8cd2e26b8f0c9d481e13b75872e0fa9cec052e519b"
	"click==8.5.1 --hash=sha256:8bb5376d2006950386f8c6427613334a2acadc5f559cb80e638d00b4df957e37"
)
[ -f "$android_root/commit" ] || { echo "no build in $android_root: run android-build.sh first" >&2; exit 1; }
built=$(cut -c 1-12 "$android_root/commit")
rebuilt=$(unsigned_build_in "$android_root/out")
work=$(mktemp -d)
readonly built rebuilt work
trap 'rm -rf "$work"' EXIT

fail() {
	echo "✗ $(basename "$1") $2" >&2
	exit 1
}

signed_by_one_pinned_key() {
	is_sha256_digest "$2" || fail "$1" "is not signed by exactly one key"
	matches_pin "$3" "$2" || fail "$1" "is signed by $2, not by the certificate pinned in android/$3-certificate.sha256"
}

entries() {
	unzip -l "$1" | awk 'NR > 3 && NF >= 4 { $2 = $3 = ""; print }'
}

if ! command -v apksigcopier >/dev/null; then
	command -v uv >/dev/null || { echo "apksigcopier or uv is required" >&2; exit 1; }
	printf '%s\n' "${apksigcopier_requirements[@]}" > "$work/requirements.txt"
	uv venv -q --python '>=3.10' "$work/venv"
	uv pip install -q --python "$work/venv" --require-hashes -r "$work/requirements.txt"
	PATH=$work/venv/bin:$PATH
fi
apksigcopier copy "$published_apk" "$rebuilt.apk" "$work/copied.apk" || fail "$published_apk" "has no APK signature to copy"
cmp -s "$work/copied.apk" "$published_apk" || fail "$published_apk" "is not the build of $built with only a signature added"
apk_certificate=$(apk_certificates "$published_apk") || fail "$published_apk" "has no valid signature"
signed_by_one_pinned_key "$published_apk" "$apk_certificate" release
echo "✓ $(basename "$published_apk") is the build of $built with only a signature added, by $apk_certificate"

[ -n "$published_aab" ] || exit 0
verified=$(jarsigner -verify "$published_aab") || fail "$published_aab" "has no valid JAR signature"
if ! grep -q '^jar verified\.$' <<<"$verified" || grep -q 'unsigned entries' <<<"$verified"; then
	fail "$published_aab" "has no JAR signature over all its entries"
fi
diff <(entries "$rebuilt.aab") <(entries "$published_aab" | grep -v -E " $jar_signature\$") >&2 ||
	fail "$published_aab" "has other entries than the build of $built and a JAR signature"
signature=()
while IFS= read -r entry; do signature+=("$entry"); done < <(unzip -Z1 "$published_aab" | grep -E "^$jar_signature\$")
cmp -s <(unzip -p "$rebuilt.aab") <(unzip -p "$published_aab" -x "${signature[@]}") ||
	fail "$published_aab" "has other contents than the build of $built"
aab_certificate=$(aab_certificates "$published_aab")
signed_by_one_pinned_key "$published_aab" "$aab_certificate" upload
echo "✓ $(basename "$published_aab") is the build of $built with only a JAR signature added, by $aab_certificate"
