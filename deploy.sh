#!/usr/bin/env bash
set -e

log() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] [$1] $2"
}

I="INFO"
W="WARNING"
E="ERROR"
S="SUCCESS"

QUADLET_DIR="$HOME/.config/containers/systemd"
USER_UNIT_DIR="$HOME/.config/systemd/user"
PROJECT_DIR="$HOME/projects/init-iac"

log "$I" "Проверка окружения."
log "$I" "Пользователь: $USER."
log "$I" "Домашняя директория: $HOME."

if [ ! -S "/run/user/$UID/podman/podman.sock" ]; then
    log "$W" "Сокет Podman не найден. Запустите: systemctl --user enable --now podman.socket"
fi

log "$I" "Подготовка директорий."
mkdir -p "$QUADLET_DIR"
mkdir -p "$USER_UNIT_DIR"

log "$I" "Контейнеры и сети. Создаю симлинки Quadlet-сети."
ln -sf "$PROJECT_DIR/traefik-public.network" "$QUADLET_DIR/"

log "$I" "Сервисы и таймеры. Создаю симлинки systemd-юнитов."
ln -sf "$PROJECT_DIR/podman-prune.service" "$USER_UNIT_DIR/"
ln -sf "$PROJECT_DIR/podman-prune.timer" "$USER_UNIT_DIR/"

log "$I" "Включение linger."
loginctl enable-linger "$USER"

log "$I" "Перезагрузка конфигурации systemd"
systemctl --user daemon-reload

log "$S" "Публичная сеть:"
podman network ls | grep traefik

log "$I" "Активация таймеров."
systemctl --user enable --now podman-prune.timer

log "$S" "Новый таймер:"
systemctl --user list-timers | grep podman-prune

log "$S" "База для разворачивания rootless сервисов подготовлена."