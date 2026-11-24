#!/bin/bash
set -euo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

[ $# -eq 0 ] || { echo "usage: ios-release.sh" >&2; exit 2; }
source "$(dirname "${BASH_SOURCE[0]}")/ios-build.sh"

if [ -n "$(git -C "$repo" status --porcelain)" ]; then
	echo "commit or stash your changes first" >&2
	exit 1
fi
lock_root "$ios_release_root"
archive "$ios_release_root" -allowProvisioningUpdates
hermetic xcodebuild -exportArchive -archivePath "$ios_release_root/Espivalka.xcarchive" -exportOptionsPlist "$ios_release_root/src/ios/ExportOptions.plist" \
	-exportPath "$ios_release_root/export" -allowProvisioningUpdates > "$ios_release_root/export.log" 2>&1 ||
	{ echo "the upload failed, see $ios_release_root/export.log" >&2; exit 1; }

info() { plutil -extract "$1" raw -o - "$(archived_app "$ios_release_root")/Info.plist"; }
echo "uploaded Espivalka $(info CFBundleShortVersionString) ($(info CFBundleVersion)) of $commit to App Store Connect"
