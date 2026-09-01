#!/usr/bin/env bash
# Levanta el stack en dos fases para evitar errores de dependencias.
# Uso: bash scripts/up.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

if [[ ! -f .env ]]; then
  echo "Error: falta .env (cp .env.example .env)"
  exit 1
fi

wait_healthy() {
  local container="$1"
  local tries=0
  local max_tries=60
  local status

  while [[ $tries -lt $max_tries ]]; do
    status=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$container" 2>/dev/null || echo "missing")
    if [[ "$status" == "healthy" ]]; then
      echo "  $container: healthy"
      return 0
    fi
    tries=$((tries + 1))
    sleep 5
    echo "  ... esperando $container ($status) ($tries/$max_tries)"
  done

  echo "Error: '$container' no pasó el healthcheck."
  docker compose logs --tail=40 "${container#nas-}"
  return 1
}

echo "==> Fase 1: bases de datos y cachés..."
docker compose up -d mariadb postgres redis-nextcloud redis-immich

echo "==> Esperando a que MariaDB y PostgreSQL estén listos..."
wait_healthy nas-mariadb
wait_healthy nas-postgres

echo "==> Fase 2: resto de servicios..."
docker compose up -d

echo ""
docker compose ps
echo ""
echo "Stack levantado. Si algún servicio falla:"
echo "  docker compose logs -f nextcloud"
echo "  docker compose logs -f immich-server"
