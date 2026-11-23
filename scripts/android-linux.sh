#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/android-pins.sh"

readonly image=docker.io/library/debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2
readonly usage="usage: android-linux.sh [commit] [amd64|arm64]"
[ $# -le 2 ] || { echo "$usage" >&2; exit 2; }
readonly arch=${2:-amd64}
[ "$arch" = amd64 ] || [ "$arch" = arm64 ] || { echo "$usage" >&2; exit 2; }
repo=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)
commit=$(git -C "$repo" rev-parse --verify "${1:-HEAD}^{commit}")
engine=$(command -v docker || command -v podman) || { echo "docker or podman is required" >&2; exit 1; }
readonly repo commit engine
readonly out=$android_root-linux-$arch

rm -rf "$out"
mkdir -p "$out"
"$engine" run --rm --platform "linux/$arch" -v "$repo:/repo:ro" -v "$out:/out" \
	-e COMMIT="$commit" -e OWNER="$(id -u):$(id -g)" "$image" bash -c '
	set -euo pipefail
	apt-get update -qq
	DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends ca-certificates git > /dev/null
	git -c safe.directory="*" clone -q --no-checkout /repo /src
	git -C /src checkout -q --detach "$COMMIT"
	source /src/scripts/android-pins.sh
	trap '\''cp "$android_root/build.log" /out/ 2>/dev/null || true; chown -R "$OWNER" /out'\'' EXIT
	/src/scripts/android-sdk.sh /opt/android-sdk
	JAVA_HOME=$(debian_java_home) ANDROID_HOME=/opt/android-sdk /src/scripts/android-build.sh "$COMMIT"
	cp "$android_root"/out/* /out/
'
echo "copied the linux/$arch build of $commit to $out"
