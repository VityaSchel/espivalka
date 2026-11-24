#!/bin/bash
set -euo pipefail

[ $# -eq 1 ] || { echo "usage: altstore-adp.sh <alternative distribution package ID from App Store Connect>" >&2; exit 2; }
readonly api=https://api.altstore.io/adps
curl -fsS -X POST -H 'Content-Type: application/json' --data "$(jq -n --arg id "$1" '{adpID: $id}')" "$api" > /dev/null
while url=$(curl -fsS "$api/$1" | jq -r '.downloadURL // empty') && [ -z "$url" ]; do
	sleep 30
done
echo "$url"
