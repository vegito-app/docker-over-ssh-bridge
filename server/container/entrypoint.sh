#!/usr/bin/env bash

set -euo pipefail

debian-docker-entrypoint.sh echo "[ENTRYPOINT:] debian docker container entrypoint success"

debian-golang-container-entrypoint.sh echo "[ENTRYPOINT:] debian project container entrypoint success"

project-container-entrypoint.sh echo "[ENTRYPOINT:] debian project container entrypoint success"

docker-ssh-bridge-install.sh

exec "$@"
