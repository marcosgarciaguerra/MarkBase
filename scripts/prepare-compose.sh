#!/usr/bin/env bash
# Prepara carpetas y valida .env antes de levantar el stack.
# Uso: bash scripts/prepare-compose.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: no existe .env"
  echo "Copia la plantilla: cp .env.example .env"
  exit 1
fi

set -a
# shellcheck source=/dev/null
source "$ENV_FILE"
set +a

: "${NAS_DATA_PATH:?NAS_DATA_PATH no definido en .env}"

echo "==> Creando carpetas en ${NAS_DATA_PATH}..."
sudo mkdir -p \
  "${NAS_DATA_PATH}/nextcloud" \
  "${NAS_DATA_PATH}/immich" \
  "${NAS_DATA_PATH}/media/movies" \
  "${NAS_DATA_PATH}/media/series" \
  "${NAS_DATA_PATH}/media/music" \
  "${NAS_DATA_PATH}/backups" \
  "${NAS_DATA_PATH}/docker/caddy/data" \
  "${NAS_DATA_PATH}/docker/caddy/config" \
  "${NAS_DATA_PATH}/docker/mariadb" \
  "${NAS_DATA_PATH}/docker/redis" \
  "${NAS_DATA_PATH}/docker/redis-immich" \
  "${NAS_DATA_PATH}/docker/postgres" \
  "${NAS_DATA_PATH}/docker/immich/model-cache" \
  "${NAS_DATA_PATH}/docker/jellyfin/config" \
  "${NAS_DATA_PATH}/docker/jellyfin/cache"

if [[ -n "${SUDO_USER:-}" ]]; then
  sudo chown -R "${SUDO_USER}:${SUDO_USER}" "${NAS_DATA_PATH}"
fi

echo "==> Validando docker compose..."
cd "$PROJECT_DIR"
docker compose config >/dev/null

echo ""
echo "Preparación completada. Ahora ejecuta:"
echo "  bash scripts/up.sh"
