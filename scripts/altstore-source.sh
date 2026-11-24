#!/bin/bash
set -euo pipefail

[ $# -eq 2 ] || { echo "usage: altstore-source.sh <Apple ID of the app> <directory of Apple's alternative distribution package>" >&2; exit 2; }
repo=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)
readonly repo app_id=$1 adp=$2
readonly pbxproj=$repo/ios/Espivalka.xcodeproj/project.pbxproj
readonly site=https://git.hloth.dev/hloth/espivalka
readonly raw=$site/raw/branch/main
[ -f "$adp/manifest.json" ] || { echo "no manifest.json in $adp" >&2; exit 1; }

setting() { sed -n "s/^.*$1 = \"\{0,1\}\([^\";]*\)\"\{0,1\};\$/\1/p" "$pbxproj" | sort -u | head -1; }
text() { tr -d '\n' < "$repo/fastlane/metadata/en-US/$1.txt"; }
version=$(setting MARKETING_VERSION)
tag=$(git -C "$repo" describe --tags --abbrev=0)
readonly tag
release=$site/releases/download/$tag
ipa=$(find "$adp" -name '*.ipa' | LC_ALL=C sort | head -1)
[ -n "$ipa" ] || { echo "no IPA in $adp" >&2; exit 1; }

assets=$(find "$adp" -type f | LC_ALL=C sort | while IFS= read -r file; do
	name=$(basename "$file")
	jq -n --arg name "${name%.*}" --arg url "$release/$name" '{($name): $url}'
done | jq -s add)
screenshots=$(cd "$repo/fastlane/screenshots/en-US" && find . -name 'large-*.png' | LC_ALL=C sort | sed 's#^\./##' | jq -R --arg raw "$raw" '$raw + "/fastlane/screenshots/en-US/" + .' | jq -s .)

jq -n \
	--arg id "$app_id" --arg bundle "$(setting PRODUCT_BUNDLE_IDENTIFIER)" --arg description "$(text description)" --arg raw "$raw" --arg site "$site" \
	--arg version "$version" --arg build "$(setting CURRENT_PROJECT_VERSION)" --arg date "$(date -u +%Y-%m-%d)" --arg minimum "$(setting IPHONEOS_DEPLOYMENT_TARGET)" \
	--arg photos "$(setting INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription)" --arg manifest "$release/manifest.json" --argjson size "$(wc -c < "$ipa" | tr -d ' ')" \
	--argjson assets "$assets" --argjson screenshots "$screenshots" '{
	name: "Espivalka",
	subtitle: $description,
	iconURL: ($raw + "/fastlane/metadata/android/en-US/images/icon.png"),
	website: $site,
	tintColor: "#6400fd",
	apps: [{
		name: "Espivalka",
		bundleIdentifier: $bundle,
		marketplaceID: $id,
		developerName: "Viktor Shchelochkov",
		subtitle: $description,
		localizedDescription: $description,
		iconURL: ($raw + "/fastlane/metadata/android/en-US/images/icon.png"),
		tintColor: "#6400fd",
		category: "lifestyle",
		screenshots: $screenshots,
		versions: [{
			version: $version,
			buildVersion: $build,
			date: $date,
			downloadURL: $manifest,
			assetURLs: $assets,
			size: $size,
			minOSVersion: $minimum
		}],
		appPermissions: {entitlements: [], privacy: {NSPhotoLibraryAddUsageDescription: $photos}}
	}],
	news: []
}'
