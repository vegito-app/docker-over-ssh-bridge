#!/usr/bin/env bash

set -euo pipefail

mkdir -p /var/run/sshd

echo Generating server HostKeys for sshd
ssh-keygen -A

echo Setting correct permission for directory /etc/ssh/
sudo chmod -R 755 /etc/ssh/

echo granting access to ${SSH_PUBLIC_KEY}
cat ${SSH_PUBLIC_KEY}

docker-ssh-bridge-ensure-vscode-servers.sh

generate_ssh_env() {
    local ssh_env="${HOME}/.ssh/environment"
    local sshd_env_conf="/etc/ssh/sshd_config.d/99-${USER}-environment.conf"

    mkdir -p ${HOME}/.ssh
    chown ${USER}:${USER} ${HOME}/.ssh
    chmod 700 ${HOME}/.ssh

    {
        echo "VEGITO_DOCKER_REGISTRIES=${VEGITO_DOCKER_REGISTRIES:-}"
        echo "VEGITO_DOCKERHUB_PAT=${VEGITO_DOCKERHUB_PAT:-}"
        echo "VEGITO_DOCKER_REGISTRY_MODE=${VEGITO_DOCKER_REGISTRY_MODE:-}"
        echo "VEGITO_STRIPE_DEBUG_KEY=${VEGITO_STRIPE_DEBUG_KEY:-}"
        echo "VEGITO_STRIPE_WEBHOOK_SECRET=${VEGITO_STRIPE_WEBHOOK_SECRET:-}"
        echo "VEGITO_STRIPE_PROD_KEY=${VEGITO_STRIPE_PROD_KEY:-}"
        echo "VEGITO_PROJECT_USER=${VEGITO_PROJECT_USER:-}"
        echo "VEGITO_DOCKERHUB_USERNAME=${VEGITO_DOCKERHUB_USERNAME:-}"
        echo "VSCODE_SERVER_ARCH=${VSCODE_SERVER_ARCH:-}"
        echo "VSCODE_SERVER_COMMIT=${VSCODE_SERVER_COMMIT:-}"
        echo "VEGITO_DOCKER_COMPOSE_HOST=${VEGITO_DOCKER_COMPOSE_HOST:-}"
    } > "${ssh_env}"

    chown ${USER}:${USER} "${ssh_env}"
    chmod 600 "${ssh_env}"

    {
        echo "PermitUserEnvironment yes"
    } | sudo tee "${sshd_env_conf}"

    sudo chmod 644 "${sshd_env_conf}"

    echo "Generated SSH environment at ${ssh_env}"
}

generate_ssh_env