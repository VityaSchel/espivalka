#!/bin/bash
set -euo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
source "$(dirname "${BASH_SOURCE[0]}")/ios-pins.sh"

[ $# -eq 1 ] || { echo "usage: ios-verify.sh <published ipa>, after ios-build.sh <commit>" >&2; exit 2; }
[ -f "$ios_root/commit" ] || { echo "no build in $ios_root: run ios-build.sh first" >&2; exit 1; }
read -r commit epoch < "$ios_root/commit"
rebuilt=$(echo "$ios_root"/out/espivalka-v*-ios.ipa)
[ -f "$rebuilt" ] || { echo "no IPA in $ios_root/out: run ios-build.sh again" >&2; exit 1; }
name=$(basename "$1")
work=$(mktemp -d)
readonly commit epoch rebuilt name work
trap 'rm -rf "$work"' EXIT

fail() {
	echo "✗ $name $1" >&2
	exit 1
}
entries() { zipinfo -1 "$1" | LC_ALL=C sort; }
listing() {
	(cd "$1" && find . | LC_ALL=C sort | while IFS= read -r path; do
		printf '%s %s %s\n' "$(stat -f %p "$path")" "$(test -f "$path" && shasum -a 256 < "$path" | cut -c 1-64)" "$path"
	done)
}

shasum -a 256 "$1" "$rebuilt"
if cmp -s "$1" "$rebuilt"; then
	echo "✓ $name is byte for byte the build of ${commit:0:12}"
	exit 0
fi

diff <(entries "$1") <(entries "$rebuilt") >&2 || fail "holds other files than the build of ${commit:0:12}"
! grep -q '^l' <(zipinfo "$1") || fail "holds symbolic links"
ditto -x -k --norsrc --noextattr --noacl "$1" "$work/published"
ditto -x -k "$rebuilt" "$work/rebuilt"
readonly app=$work/published/Payload/Espivalka.app
if ! codesign --verify --strict "$app" 2>/dev/null || [ -n "$(codesign -d --entitlements - --xml "$app" 2>/dev/null)" ]; then
	fail "is not validly signed without entitlements"
fi

seal "$work/published" "$work/resealed.ipa" "$epoch"
if cmp -s "$work/resealed.ipa" "$rebuilt"; then
	echo "✓ $name is the build of ${commit:0:12} with a different signature or zip layout"
	exit 0
fi
diff <(listing "$work/published") <(listing "$work/rebuilt") >&2 || true
fail "is not the build of ${commit:0:12} with Xcode $xcode_build on macOS build $(sw_vers -buildVersion)"
