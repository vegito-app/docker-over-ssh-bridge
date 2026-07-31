ARG debian=dbndev/vegito-public:trixie-debian-golang-latest
FROM ${debian} AS go-build
ARG debian_version=trixie
ARG TARGETPLATFORM

ARG uid=1000
ARG gid=1000
ARG go_pkg=/home/debian/go/pkg
ARG go_cache=/home/debian/.cache/go-build
ENV GOMODCACHE=${go_pkg}/mod
ENV GOCACHE=${go_cache}
ENV GOBIN=/home/debian/go/bin
ENV CGO_ENABLED=0
RUN --mount=type=cache,id=vegito-debian-${TARGETPLATFORM}-${debian_version}-root-go-pkg,target=${go_pkg},sharing=locked,uid=${uid},gid=${gid} \
    --mount=type=cache,id=vegito-debian-${TARGETPLATFORM}-${debian_version}-root-go-build,target=${go_cache},sharing=locked,uid=${uid},gid=${gid} \
    go install -v github.com/jesseduffield/lazydocker@latest

FROM debian:bookworm

# Mise à jour du système et installation sudo, openssh-client, openssh-server, netcat
RUN apt-get update && apt-get install -y \
    bash-completion \
    curl \
    git \
    btop \
    htop \
    jq \
    make \
    net-tools \
    netcat-openbsd \
    openssh-client \
    openssh-server \
    procps \
    socat \
    sudo \
    tini \
    tmux \
    tree \
    unzip \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Configuration du server SSH
RUN mkdir /var/run/sshd

ENV USER=devuser

# Création d'un nouvel utilisateur sans mot de passe
RUN useradd -m ${USER} && echo "${USER}:${USER}" | chpasswd && adduser ${USER} sudo \
    && echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/devuser \
    && chmod 0440 /etc/sudoers.d/devuser

# Install Docker (client part)
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    # Add the repository to Apt sources:
    && echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update && apt-get install -y \
    # docker-ce \
    docker-ce-cli \
    # containerd.io \
    # docker-buildx-plugin \
    docker-compose-plugin

# Configuration des permissions correctes pour le dossier .ssh
RUN mkdir /workspaces && \
    chmod 707 /workspaces

USER ${USER}
ENV HOME=/home/${USER}

# Configuration des permissions correctes pour le dossier .ssh
RUN mkdir ${HOME}/.ssh && \
    chmod 700 ${HOME}/.ssh

COPY container/ensure-vscode-servers.sh /usr/local/bin/docker-ssh-bridge-ensure-vscode-servers.sh
COPY container/entrypoint.sh            /usr/local/bin/docker-ssh-bridge-entrypoint.sh
COPY container/install.sh               /usr/local/bin/docker-ssh-bridge-install.sh
COPY container/run.sh                   /usr/local/bin/docker-ssh-bridge-run.sh
COPY container/healthcheck.sh           /usr/local/bin/docker-ssh-bridge-healthcheck.sh

# called from entrypoint so the /vscode volume is mounted
COPY container/vscode-server-install.sh /usr/local/bin/docker-ssh-bridge-vscode-server-install.sh
# called from entrypoint so the /vscode volume is mounted
COPY container/vscode-remote-containers-server-install.sh   /usr/local/bin/docker-ssh-bridge-vscode-remote-containers-server-install.sh

ENTRYPOINT [ "tini", "--", "docker-ssh-bridge-entrypoint.sh" ]
CMD [ "docker-ssh-bridge-run.sh" ]
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD [ "docker-ssh-bridge-healthcheck.sh" ]

COPY --from=go-build /home/debian/go/bin/lazydocker /usr/local/bin/lazydocker