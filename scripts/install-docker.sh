#!/usr/bin/env bash
# Instala Docker Engine, Docker Compose plugin y Tailscale en Debian/Ubuntu.
# Uso: sudo bash scripts/install-docker.sh

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Ejecuta este script como root: sudo bash $0"
  exit 1
fi

echo "==> Actualizando paquetes..."
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release

echo "==> Instalando Docker Engine..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "==> Habilitando Docker al arranque..."
systemctl enable docker
systemctl start docker

# Añadir usuario actual al grupo docker si se ejecuta con sudo
if [[ -n "${SUDO_USER:-}" ]]; then
  usermod -aG docker "$SUDO_USER"
  echo "Usuario '$SUDO_USER' añadido al grupo docker."
  echo "Cierra sesión y vuelve a entrar para aplicar los permisos."
fi

echo "==> Instalando Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

echo "==> Instalando utilidades adicionales..."
apt-get install -y ufw unattended-upgrades restic

echo "==> Configurando actualizaciones automáticas de seguridad..."
dpkg-reconfigure -plow unattended-upgrades

echo ""
echo "=== Instalación completada ==="
echo ""
echo "Docker:    $(docker --version)"
echo "Compose:   $(docker compose version)"
echo ""
echo "Siguientes pasos:"
echo "  1. sudo bash scripts/mount-data-disk.sh"
echo "  2. sudo tailscale up"
echo "  3. cp .env.example .env && nano .env"
echo "  4. docker compose up -d"
