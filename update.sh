#!/bin/bash
set -xe
cd "$(dirname "$0")"
docker compose pull
docker compose build --pull
docker compose up -d
docker system prune -f
