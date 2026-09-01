#!/usr/bin/env bash
# Monta el disco de datos en /srv/nas y crea la estructura de carpetas.
# Uso: sudo bash scripts/mount-data-disk.sh [dispositivo]
# Ejemplo: sudo bash scripts/mount-data-disk.sh /dev/sdb1

set -euo pipefail

MOUNT_POINT="/srv/nas"
NAS_USER="${SUDO_USER:-nasadmin}"

if [[ $EUID -ne 0 ]]; then
  echo "Ejecuta este script como root: sudo bash $0"
  exit 1
fi

if [[ $# -eq 0 ]]; then
  echo "Discos disponibles:"
  lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
  echo ""
  read -rp "Introduce el dispositivo de datos (ej. /dev/sdb1): " DEVICE
else
  DEVICE="$1"
fi

if [[ ! -b "$DEVICE" ]]; then
  echo "Error: '$DEVICE' no es un dispositivo de bloque válido."
  exit 1
fi

FSTYPE=$(blkid -o value -s TYPE "$DEVICE" 2>/dev/null || true)

if [[ -z "$FSTYPE" ]]; then
  echo "El dispositivo no tiene sistema de archivos. ¿Formatear como ext4? (s/N)"
  read -r CONFIRM
  if [[ "$CONFIRM" =~ ^[sS]$ ]]; then
    mkfs.ext4 -L nas-data "$DEVICE"
    FSTYPE="ext4"
  else
    echo "Abortado."
    exit 1
  fi
fi

mkdir -p "$MOUNT_POINT"

if ! grep -q "$MOUNT_POINT" /etc/fstab; then
  UUID=$(blkid -o value -s UUID "$DEVICE")
  echo "UUID=$UUID  $MOUNT_POINT  ext4  defaults,nofail  0  2" >> /etc/fstab
  echo "Entrada añadida a /etc/fstab (UUID=$UUID)"
fi

mount -a

echo "==> Creando estructura de carpetas en $MOUNT_POINT..."
mkdir -p "$MOUNT_POINT"/{nextcloud,immich,media/{movies,series,music},backups,docker}
mkdir -p "$MOUNT_POINT/docker"/{caddy,nextcloud,mariadb,redis,immich,postgres,jellyfin}

chown -R "$NAS_USER:$NAS_USER" "$MOUNT_POINT"
chmod -R 755 "$MOUNT_POINT"

echo ""
echo "=== Disco montado correctamente ==="
df -h "$MOUNT_POINT"
echo ""
echo "Estructura creada:"
find "$MOUNT_POINT" -maxdepth 2 -type d | sort
