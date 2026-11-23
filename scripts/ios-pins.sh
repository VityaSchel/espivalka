readonly xcode_build=27A266a
readonly iphoneos_sdk_build=24A430
readonly ios_root=/private/tmp/espivalka-ios
readonly ios_release_root=$ios_root-release
readonly developer_dir=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}

hermetic() {
	env -i PATH="$PATH" HOME="$HOME" DEVELOPER_DIR="$developer_dir" TZ=UTC LC_ALL=C \
		GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ATTR_NOSYSTEM=1 "$@"
}

seal() {
	local dir=$1 ipa=$2 mtime=$3
	hermetic codesign --remove-signature "$dir/Payload/Espivalka.app"
	hermetic codesign --sign - --timestamp=none "$dir/Payload/Espivalka.app"
	chmod -R u=rwX,go=rX "$dir/Payload"
	find "$dir/Payload" -exec touch -h -d "$(date -u -r "$mtime" +%Y-%m-%dT%H:%M:%SZ)" {} +
	rm -f "$ipa"
	(cd "$dir" && find Payload | LC_ALL=C sort | hermetic zip -q -X -y -9 -@ "$ipa")
}
