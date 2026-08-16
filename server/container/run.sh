#!/usr/bin/env bash

set -euo pipefail

# Nettoyage du flag d'état à chaque arrêt
rm -f /tmp/.bridge-sshd-ready

# List to hold background job PIDs
bg_pids=()
sshd_pid=

cleanup() {
    for pid in "${bg_pids[@]}"; do
        kill "$pid"
        wait "$pid" 2>/dev/null
    done
}

trap "echo Exited entrypoint with code $?." EXIT

echo Starting sshd.

sudo sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
/usr/sbin/sshd -D &
sshd_pid+=($!)

until nc -z localhost 22 ; do
  echo waiting sshd...
  sleep 1
done

echo sshd started: listening at localhost:22

socat TCP-LISTEN:2375,fork UNIX-CONNECT:/var/run/docker.sock &
bg_pids+=($!)

sudo chmod o+rw /var/run/docker.sock

# Create a ready flag file for healthchecks and other services to know when the AI agent is ready
echo "{\"status\":\"ready\",\"ts\":$(date +%s)}" > /tmp/.bridge-sshd-ready

echo "✅ sshd started successfully."

# ⚠️ Not required as we have no firebase-emulators, no dockerd, do desktop-x
# project-container-start.sh

wait ${sshd_pid}