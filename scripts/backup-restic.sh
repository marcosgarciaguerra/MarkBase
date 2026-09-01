#!/usr/bin/env bash
# Backup diario con Restic: dumps de BD + datos + volúmenes Docker.
# Uso manual:  sudo bash scripts/backup-restic.sh
# Cron:        0 3 * * * /home/nasadmin/MarkBase/scripts/backup-restic.sh >> /var/log/nas-backup.log 2>&1

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"
BACKUP_STAGING="/tmp/nas-backup-staging"
DATE_TAG=$(date +%Y-%m-%d)

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
else
  echo "Error: no se encontró $ENV_FILE"
  exit 1
fi

: "${RESTIC_REPOSITORY:?RESTIC_REPOSITORY no definido en .env}"
: "${RESTIC_PASSWORD:?RESTIC_PASSWORD no definido en .env}"
: "${NAS_DATA_PATH:?NAS_DATA_PATH no definido en .env}"

export RESTIC_REPOSITORY RESTIC_PASSWORD

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

if [[ ! -d "$(dirname "$RESTIC_REPOSITORY")" ]]; then
  log "ERROR: directorio de backup no montado: $(dirname "$RESTIC_REPOSITORY")"
  log "Monta el disco USB en /mnt/backup antes de ejecutar."
  exit 1
fi

log "Iniciando backup NAS ($DATE_TAG)..."

rm -rf "$BACKUP_STAGING"
mkdir -p "$BACKUP_STAGING"/{mariadb,postgres,nextcloud-data,immich-library,media,docker-config}

# ── Dumps de bases de datos ──────────────────────────────
log "Volcando MariaDB (Nextcloud)..."
docker exec nas-mariadb mysqldump \
  -u root -p"${MYSQL_ROOT_PASSWORD}" \
  --single-transaction --all-databases \
  | gzip > "$BACKUP_STAGING/mariadb/${DATE_TAG}.sql.gz"

log "Volcando PostgreSQL (Immich)..."
docker exec nas-postgres pg_dump \
  -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" \
  | gzip > "$BACKUP_STAGING/postgres/${DATE_TAG}.sql.gz"

# ── Copia de datos ───────────────────────────────────────
log "Copiando datos de Nextcloud..."
rsync -a --delete "${NAS_DATA_PATH}/nextcloud/" "$BACKUP_STAGING/nextcloud-data/"

log "Copiando biblioteca Immich..."
rsync -a --delete "${NAS_DATA_PATH}/immich/" "$BACKUP_STAGING/immich-library/"

log "Copiando media..."
rsync -a "${NAS_DATA_PATH}/media/" "$BACKUP_STAGING/media/"

log "Copiando configuración Docker..."
cp "$PROJECT_DIR/docker-compose.yml" "$BACKUP_STAGING/docker-config/"
cp "$PROJECT_DIR/.env" "$BACKUP_STAGING/docker-config/env.backup"
cp -r "$PROJECT_DIR/caddy" "$BACKUP_STAGING/docker-config/"

# ── Restic ───────────────────────────────────────────────
log "Inicializando repositorio Restic (si no existe)..."
restic snapshots &>/dev/null || restic init

log "Ejecutando backup Restic..."
restic backup "$BACKUP_STAGING" --tag daily --tag "$DATE_TAG"

log "Limpiando snapshots antiguos (mantener 7 diarios, 4 semanales, 6 mensuales)..."
restic forget \
  --tag daily \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6 \
  --prune

log "Verificando integridad..."
restic check --read-data-subset=5%

rm -rf "$BACKUP_STAGING"

log "Backup completado correctamente."
restic snapshots --last 3
