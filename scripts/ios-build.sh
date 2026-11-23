#!/bin/bash
set -euo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
source "$(dirname "${BASH_SOURCE[0]}")/ios-pins.sh"

[ $# -le 1 ] || { echo "usage: ios-build.sh [commit]" >&2; exit 2; }
repo=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)
commit=$(git -C "$repo" rev-parse --verify "${1:-HEAD}^{commit}")
epoch=$(git -C "$repo" log -1 --no-show-signature --format=%ct "$commit")
info_attributes=$(git -C "$repo" rev-parse --path-format=absolute --git-path info/attributes)
readonly repo commit epoch info_attributes

found=$(hermetic xcodebuild -version 2>/dev/null | awk '/Build version/ { print $3 }') || true
found_sdk=$(hermetic xcrun --sdk iphoneos --show-sdk-build-version 2>/dev/null) || true
readonly found found_sdk
if [ "$found" != "$xcode_build" ] || [ "$found_sdk" != "$iphoneos_sdk_build" ]; then
	echo "Xcode $xcode_build with iOS SDK $iphoneos_sdk_build is required, found Xcode ${found:-none} with iOS SDK ${found_sdk:-none} at $developer_dir" >&2
	exit 1
fi
if [ -e "$info_attributes" ]; then
	echo "move $info_attributes away, git archive would apply it to the sources of $commit" >&2
	exit 1
fi

lock_root() {
	mkdir "$1.lock" 2>/dev/null || { echo "$1 is in use by another ios-build.sh or ios-release.sh, or remove $1.lock" >&2; exit 1; }
	lock=$1.lock
	trap 'rmdir "$lock"' EXIT
}

archived_app() { echo "$1/Espivalka.xcarchive/Products/Applications/Espivalka.app"; }

require_declared_reasons() {
	local app=$1 manifest=$1/PrivacyInfo.xcprivacy imported strings used category declared=" " index=0
	imported=$(hermetic xcrun nm -u "$app/Espivalka" | sed -E 's/^_//; s/[$]INODE64$//')
	strings=$(hermetic xcrun strings -a "$app/Espivalka")
	used=$({
		awk '
			/^(f?stat|fstatat|lstat|NSURL(ContentModification|Creation)DateKey|NSFile(Modification|Creation)Date)$/ { print "FileTimestamp" }
			/^(f?getattrlist|getattrlistbulk|getattrlistat)$/ { print "FileTimestamp"; print "DiskSpace" }
			/^(f?statv?fs|NSURLVolume(AvailableCapacity(ForImportantUsage|ForOpportunisticUsage)?|TotalCapacity)Key|NSFileSystem(Free)?Size)$/ { print "DiskSpace" }
			/^mach_absolute_time$/ { print "SystemBootTime" }' <<<"$imported"
		awk '
			/^(creation|modification|fileModification)Date$/ { print "FileTimestamp" }
			/^systemUptime$/ { print "SystemBootTime" }
			/^activeInputModes$/ { print "ActiveKeyboards" }
			/^(standardUserDefaults|initWithSuiteName:)$/ { print "UserDefaults" }' <<<"$strings"
	} | sort -u)
	while category=$(plutil -extract "NSPrivacyAccessedAPITypes.$index.NSPrivacyAccessedAPIType" raw -o - "$manifest" 2>/dev/null); do
		if plutil -extract "NSPrivacyAccessedAPITypes.$index.NSPrivacyAccessedAPITypeReasons.0" raw -o - "$manifest" > /dev/null 2>&1; then
			declared+="${category#NSPrivacyAccessedAPICategory} "
		fi
		index=$((index + 1))
	done
	for category in $used; do
		[[ $declared == *" $category "* ]] || { echo "Espivalka uses $category APIs that PrivacyInfo.xcprivacy does not declare with a reason" >&2; exit 1; }
	done
}

archive() {
	local root=$1
	shift
	rm -rf "$root"
	mkdir -m 700 "$root"
	mkdir "$root/src"
	hermetic git -C "$repo" -c core.autocrlf=false -c core.attributesFile=/dev/null archive "$commit" | tar -x -C "$root/src"
	hermetic SOURCE_DATE_EPOCH="$epoch" xcodebuild -project "$root/src/ios/Espivalka.xcodeproj" -scheme Espivalka -configuration Release \
		-destination generic/platform=iOS -derivedDataPath "$root/build" -archivePath "$root/Espivalka.xcarchive" "$@" archive > "$root/build.log" 2>&1 ||
		{ echo "the build failed, see $root/build.log" >&2; exit 1; }
	require_declared_reasons "$(archived_app "$root")"
}

package() {
	local app=$ios_root/ipa/Payload/Espivalka.app version
	ditto --norsrc --noextattr --noacl "$(archived_app "$ios_root")" "$app"
	plutil -remove BuildMachineOSBuild "$app/Info.plist"
	plutil -convert xml1 "$app/Info.plist"
	version=$(plutil -extract CFBundleShortVersionString raw -o - "$app/Info.plist")
	mkdir "$ios_root/out"
	seal "$ios_root/ipa" "$ios_root/out/espivalka-v$version-ios.ipa" "$epoch"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
	lock_root "$ios_root"
	archive "$ios_root" DEVELOPMENT_TEAM= CODE_SIGNING_ALLOWED=NO
	package
	echo "$commit $epoch" > "$ios_root/commit"
	(cd "$ios_root/out" && shasum -a 256 -- *.ipa)
	echo "built $commit with Xcode $found and iOS SDK $found_sdk on macOS $(sw_vers -productVersion) build $(sw_vers -buildVersion) into $ios_root/out"
fi
