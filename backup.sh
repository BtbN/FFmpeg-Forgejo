#!/bin/bash
set -e
cd "$(dirname "$0")"
source .env
set -x

if [[ -f ~/mount_backups.sh ]]; then
	bash ~/mount_backups.sh
fi

docker run --pull=always --rm -u root -w / \
	--mount type=bind,src="$PWD",dst=/workdir \
	ubuntu:latest rm -rf /workdir/cur_backup

mkdir -p ~/backups
mkdir -p cur_backup/bucket
rclone mount --use-server-modtime --read-only --allow-other forgejo:code-ffmpeg-storage/ ./cur_backup/bucket &
trap "jobs -p | xargs -r kill; docker compose up -d; mountpoint -q '$HOME/backups' && umount '$HOME/backups' || true; wait; docker run --rm -u root --mount type=bind,src='$PWD',dst=/workdir ubuntu:latest rm -rf /workdir/cur_backup" EXIT

cp .env cur_backup/envfile.env

docker compose stop forgejo

docker run --rm -u root -w / \
	--mount type=bind,src=/,dst=/workdir \
	ubuntu:latest cp -a --reflink=always "/workdir$FORGEJO_DATA_DIR" "/workdir$PWD/cur_backup/data"
docker compose exec -T db mariadb-dump --opt --single-transaction --extended-insert -u "$FORGEJO_DB_USER" --password="$FORGEJO_DB_PASSWORD" "$FORGEJO_DB_DATABASE" | gzip > cur_backup/database.sql.gz &
DUMP_PID="$!"
sleep 5

docker compose start forgejo
wait "$DUMP_PID"

docker run --rm -u root -w / \
	--mount type=bind,src="$PWD"/cur_backup,dst=/cur_backup,readonly \
	ubuntu:latest tar --xattrs --acls --exclude=./cur_backup/bucket/repo-archive -zpc ./cur_backup > ~/backups/"$(date "+%s")".tar.gz
