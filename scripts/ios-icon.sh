#!/bin/bash
set -euo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
source "$(dirname "${BASH_SOURCE[0]}")/ios-pins.sh"

[ $# -eq 0 ] || { echo "usage: ios-icon.sh" >&2; exit 2; }
ios=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)/ios
work=$(mktemp -d)
readonly ios work catalog=$work/AppIcon.xcassets
trap 'rm -rf "$work"' EXIT

mkdir "$catalog"
cp -R "$ios/AppIcon.appiconset" "$catalog"
hermetic sips -s format png "$ios/AppIcon.svg" --out "$catalog/AppIcon.appiconset/AppIcon.png" > /dev/null

deployment_target=$(sed -n 's/^.*IPHONEOS_DEPLOYMENT_TARGET = \(.*\);$/\1/p' "$ios/Espivalka.xcodeproj/project.pbxproj" | sort -u)
hermetic xcrun actool "$catalog" --compile "$work" --app-icon AppIcon --platform iphoneos --target-device iphone \
	--minimum-deployment-target "$deployment_target" --optimization space --errors --warnings \
	--output-format human-readable-text --output-partial-info-plist "$work/Info.plist"
cp "$work/Assets.car" "$work/AppIcon60x60@2x.png" "$ios/Espivalka/"
