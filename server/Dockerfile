ARG go=dbndev/vegito-public:trixie-debian-golang-latest
ARG debian=dbndev/vegito-public:trixie-debian-project-golang-docker-latest
FROM ${go} AS go-build
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

FROM ${debian}

ARG TARGETPLATFORM

USER root
ARG debian_version=trixie

RUN --mount=type=cache,id=vegito-debian-${debian_version}-${TARGETPLATFORM}-apt-cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,id=vegito-debian-${debian_version}-${TARGETPLATFORM}-apt-lib,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y \
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
RUN mkdir -p /var/run/sshd

USER root

ARG non_root_user=dockersshbridge
ARG uid=1000
ARG gid=1000

# 👤 Rename non root user
RUN usermod -l ${non_root_user} ${USER} \
    && groupmod -n ${non_root_user} ${USER} \
    && \
    echo "${non_root_user}:${non_root_user}" | chpasswd && \
    adduser ${non_root_user} sudo && \
    echo "${non_root_user} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${non_root_user} && \
    chmod 0440 /etc/sudoers.d/${non_root_user}

USER ${non_root_user}    

ENV USER=${non_root_user}

WORKDIR ${HOME}

ENV PATH=${PATH}:${HOME}/go/bin

# Configuration des permissions correctes pour le dossier .ssh
WORKDIR /workspaces 
RUN chmod 707 .

USER ${USER}

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