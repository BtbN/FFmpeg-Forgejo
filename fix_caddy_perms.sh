#!/bin/bash
cd "$(dirname "$0")"
docker compose up -d web
docker compose exec -u root web chown -R 983:983 /data /config
docker compose restart web
