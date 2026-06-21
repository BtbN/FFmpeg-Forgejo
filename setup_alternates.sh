#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

docker compose exec -u git forgejo bash -c '
set -euo pipefail

find /data/git/repositories -mindepth 2 -maxdepth 2 -type d -name "ffmpeg.git" | while read -r repo; do
    owner="$(basename "$(dirname "$repo")")"
    alt_file="$repo/objects/info/alternates"

    if [ "$owner" = "ffmpeg" ]; then
        continue
    fi

    if [ -e "$alt_file" ]; then
        echo "skipping existing: $alt_file"
        continue
    fi

    mkdir -p "$(dirname "$alt_file")"
    printf "../../../ffmpeg/ffmpeg.git/objects\n" >> "$alt_file"
    echo "created: $alt_file"
done
'
