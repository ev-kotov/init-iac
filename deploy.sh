#!/usr/bin/env bash
set -e

log() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] [$1] $2"
}

I="INFO"
W="WARNING"
E="ERROR"
S="SUCCESS"

log "$I" "Checking environment."
log "$I" "User: $USER."
log "$I" "Home directory: $HOME."

QUADLET_DIR="$HOME/.config/containers/systemd"
USER_UNIT_DIR="$HOME/.config/systemd/user"
PROJECT_DIR="$HOME/projects/init-iac"

if [ ! -S "/run/user/$UID/podman/podman.sock" ]; then
    log "$W" "Podman socket not found. Run: systemctl --user enable --now podman.socket"
fi

log "$I" "Preparing directories."
mkdir -p "$QUADLET_DIR"
mkdir -p "$USER_UNIT_DIR"

log "$I" "Containers and networks. Creating Quadlet network symlinks."
ln -sf "$PROJECT_DIR/traefik-public.network" "$QUADLET_DIR/"

log "$I" "Services and timers. Creating systemd unit symlinks."
ln -sf "$PROJECT_DIR/podman-prune.service" "$USER_UNIT_DIR/"
ln -sf "$PROJECT_DIR/podman-prune.timer" "$USER_UNIT_DIR/"

log "$I" "Enabling linger."
loginctl enable-linger "$USER"

log "$I" "Reloading systemd configuration"
systemctl --user daemon-reload

log "$I" "Restart Traefik-network service"
systemctl --user restart traefik-public-network.service

log "$S" "Created unit service:"
systemctl --user list-unit-files | grep traefik-public-network

log "$S" "Created public network:"
podman network ls | grep traefik

log "$I" "Activating timers."
systemctl --user enable --now podman-prune.timer

log "$S" "Created timer:"
systemctl --user list-timers | grep podman-prune

log "$S" "Base for deploying rootless services is ready."