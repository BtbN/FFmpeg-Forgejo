#!/bin/bash
set -xe
cd "$(dirname "$0")"
source .env

mkdir -p ~/backups
mkdir -p cur_backup/{bucket,data}
rclone mount --use-server-modtime --read-only --allow-other forgejo:code-ffmpeg-storage/ ./cur_backup/bucket &
trap "jobs -p | xargs -r kill; docker compose up -d; wait; rm -rf cur_backup" EXIT

cp .env cur_backup/envfile.env

docker compose stop forgejo
docker compose exec -T db mariadb-dump -u "$FORGEJO_DB_USER" --password="$FORGEJO_DB_PASSWORD" "$FORGEJO_DB_DATABASE" | gzip > cur_backup/database.sql.gz

docker run --pull=always --rm -u root -w / \
	--mount type=bind,src="$PWD"/cur_backup,dst=/cur_backup,readonly \
	--mount type=bind,src="$FORGEJO_DATA_DIR",dst=/cur_backup/data,readonly \
	ubuntu:latest tar --exclude=./cur_backup/bucket/repo-archive -zpc ./cur_backup > ~/backups/"$(date "+%s")".tar.gz
