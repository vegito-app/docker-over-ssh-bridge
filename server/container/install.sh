#!/usr/bin/env bash

set -euo pipefail
trap "echo Exited with code $?." EXIT

# Use a local directory to persist container caches and configurations across container rebuilds.
# You can override the default location by setting the CONTAINER_CACHE environment variable.
# Example: export CONTAINER_CACHE=/path/to/your/local/cache
# If CONTAINER_CACHE is not set, it will default to $LOCAL_WORKSPACE/.containers
local_container_cache=${CONTAINER_CACHE:-${LOCAL_WORKSPACE:-${PWD}}/.containers/docker-ssh-bridge}
mkdir -p $local_container_cache

# SSH configuration with persistent storage
LOCAL_WORKSPACE=${LOCAL_WORKSPACE:-.}
SSH_CLIENT_DIR=/home/debian/.ssh
SSH_PERSIST_DIR=${local_container_cache}/ssh
SSH_HOST_KEYS_DIR="${local_container_cache}/ssh-host-keys"

sudo install -d -m 700 -o root -g root \
    "${SSH_HOST_KEYS_DIR}"

if [ -L "${SSH_CLIENT_DIR}" ]; then
    rm "${SSH_CLIENT_DIR}"
fi

sudo install -d -m 700 \
    -o dockersshbridge \
    -g dockersshbridge \
    "${SSH_CLIENT_DIR}"

# Install authorized public keys
install -m 600 \
    -o dockersshbridge \
    -g dockersshbridge \
    "${LOCAL_WORKSPACE}/authorized_keys" \
    "${SSH_CLIENT_DIR}/authorized_keys"

mkdir -p "${SSH_PERSIST_DIR}"

# Fix permissions
chown -R dockersshbridge:dockersshbridge "${SSH_PERSIST_DIR}"
chmod 700 "${SSH_PERSIST_DIR}"
chmod 600 "${SSH_CLIENT_DIR}/authorized_keys"

sudo mkdir -p /var/run/sshd

# Restore or generate persistent SSH host keys
echo "Initializing persistent SSH host keys..."

for type in rsa ecdsa ed25519; do
    key="/etc/ssh/ssh_host_${type}_key"
    persistent_key="${SSH_HOST_KEYS_DIR}/ssh_host_${type}_key"

    if ! sudo test -f "${persistent_key}"; then
        sudo ssh-keygen -q -t "${type}" -N "" -f "${persistent_key}"
    fi

    sudo install -m 600 -o dockersshbridge -g dockersshbridge \
        "${persistent_key}" "${key}"

    sudo install -m 644 -o dockersshbridge -g dockersshbridge \
        "${persistent_key}.pub" "${key}.pub"
done

# Validate SSH configuration as the actual runtime user
/usr/sbin/sshd -t

echo granting access to ${SSH_PUBLIC_KEY}
cat ${SSH_PUBLIC_KEY}

docker-ssh-bridge-ensure-vscode-servers.sh

generate_ssh_env() {
    local ssh_env="${HOME}/.ssh/environment"
    local sshd_env_conf="/etc/ssh/sshd_config.d/99-${USER}-environment.conf"

    sudo install -d -m 700 \
    -o dockersshbridge \
    -g dockersshbridge \
    "${SSH_PERSIST_DIR}"

    {
        echo "VEGITO_PROJECT_USER=${VEGITO_PROJECT_USER:-}"
        
        echo "VEGITO_DNS_SERVER=${VEGITO_DNS_SERVER:-}"
        
        echo "VEGITO_STRIPE_DEBUG_KEY=${VEGITO_STRIPE_DEBUG_KEY:-}"
        echo "VEGITO_STRIPE_WEBHOOK_SECRET=${VEGITO_STRIPE_WEBHOOK_SECRET:-}"
        echo "VEGITO_STRIPE_PROD_KEY=${VEGITO_STRIPE_PROD_KEY:-}"
        
        echo "VSCODE_SERVER_ARCH=${VSCODE_SERVER_ARCH:-}"
        echo "VSCODE_SERVER_COMMIT=${VSCODE_SERVER_COMMIT:-}"

        echo "VEGITO_DOCKER_COMPOSE_HOST=${VEGITO_DOCKER_COMPOSE_HOST:-}"
        echo "VEGITO_DOCKER_PUBLIC_REPOSITORY=${VEGITO_DOCKER_PUBLIC_REPOSITORY:-}"
        echo "VEGITO_DOCKER_REGISTRIES=${VEGITO_DOCKER_REGISTRIES:-}"
        echo "VEGITO_DOCKERHUB_PAT=${VEGITO_DOCKERHUB_PAT:-}"
        echo "VEGITO_DOCKERHUB_USERNAME=${VEGITO_DOCKERHUB_USERNAME:-}"

        echo "VEGITO_DOCKER_HARDWARE_PROFILE=${VEGITO_DOCKER_HARDWARE_PROFILE:-}"
        echo "VEGITO_DOCKER_DEBIAN_DESKTOP_X_DISPLAY_MODE=${VEGITO_DOCKER_DEBIAN_DESKTOP_X_DISPLAY_MODE:-}"
        echo "LOCAL_ANDROID_GPU_MODE=${LOCAL_ANDROID_GPU_MODE:-}"
        echo "NVIDIA_DRIVER_CAPABILITIES=${NVIDIA_DRIVER_CAPABILITIES:-}"
        echo "NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES:-}"

        echo "VEGITO_DOCKER_BUILDX_ENABLE_ARM_BUILDER=${VEGITO_DOCKER_BUILDX_ENABLE_ARM_BUILDER:-}"
        echo "VEGITO_DOCKER_BUILDX_NAME=${VEGITO_DOCKER_BUILDX_NAME:-}"
        echo "VEGITO_DOCKER_BUILDX_ARM_BUILDER_ENDPOINT=${VEGITO_DOCKER_BUILDX_ARM_BUILDER_ENDPOINT:-}"
        echo "VEGITO_DOCKER_BUILDX_ARM_BUILDER_NAME=${VEGITO_DOCKER_BUILDX_ARM_BUILDER_NAME:-}"
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