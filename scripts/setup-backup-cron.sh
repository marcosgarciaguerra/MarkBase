#!/usr/bin/env bash
# Configura el cron de backup diario a las 03:00.
# Uso: bash scripts/setup-backup-cron.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SCRIPT="$SCRIPT_DIR/backup-restic.sh"
CRON_LINE="0 3 * * * $BACKUP_SCRIPT >> /var/log/nas-backup.log 2>&1"

if [[ ! -f "$BACKUP_SCRIPT" ]]; then
  echo "Error: no se encontró $BACKUP_SCRIPT"
  exit 1
fi

chmod +x "$BACKUP_SCRIPT"

if crontab -l 2>/dev/null | grep -qF "$BACKUP_SCRIPT"; then
  echo "El cron de backup ya está configurado."
else
  (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
  echo "Cron configurado: backup diario a las 03:00"
fi

echo ""
echo "Para verificar: crontab -l"
echo "Logs: tail -f /var/log/nas-backup.log"
