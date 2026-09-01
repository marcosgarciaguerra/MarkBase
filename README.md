# MarkBase — NAS casero: nube privada

Infraestructura como código para desplegar un servidor NAS en casa con sincronización de archivos, fotos, multimedia y copias de seguridad.

## Servicios incluidos

| Servicio | URL (ejemplo) | Función |
|---|---|---|
| **Nextcloud** | `https://cloud.tu-casa.lan` | Sync de archivos, calendario, contactos |
| **Immich** | `https://photos.tu-casa.lan` | Fotos y vídeos estilo Google Photos |
| **Jellyfin** | `https://media.tu-casa.lan` | Streaming de películas, series y música |
| **Caddy** | — | Reverse proxy con HTTPS interno |
| **Restic** | — | Backups incrementales cifrados |

## Requisitos de hardware

- PC viejo o mini PC (Intel N100+, 8 GB RAM mínimo, 16 GB recomendado)
- SSD 128-256 GB para el sistema operativo
- HDD 4 TB+ para datos
- Conexión Ethernet Gigabit

Consulta [docs/hardware.md](docs/hardware.md) para la guía completa de hardware.

## Instalación paso a paso

### 1. Instalar el sistema operativo

1. Descarga [Debian 12](https://www.debian.org/download) o [Ubuntu Server 24.04 LTS](https://ubuntu.com/download/server)
2. Crea un USB de instalación con [Rufus](https://rufus.ie) o `dd`
3. Instala sin entorno gráfico, crea el usuario `nasadmin`
4. Reserva una IP fija en el router para el NAS

### 2. Clonar este repositorio

```bash
git clone https://github.com/tu-usuario/MarkBase.git ~/MarkBase
cd ~/MarkBase
```

### 3. Preparar el disco de datos

```bash
sudo bash scripts/mount-data-disk.sh /dev/sdb1
```

Esto monta el disco en `/srv/nas` y crea la estructura de carpetas necesaria.

### 4. Instalar Docker y Tailscale

```bash
sudo bash scripts/install-docker.sh
```

Cierra sesión y vuelve a entrar para aplicar los permisos del grupo `docker`.

### 5. Configurar variables de entorno

```bash
cp .env.example .env
nano .env
```

Cambia **todas** las contraseñas (`changeme_*`) y ajusta `NAS_DOMAIN` a tu dominio local.

### 6. Configurar DNS local

Añade en el router o en el archivo `hosts` de cada dispositivo:

```
192.168.1.100  cloud.tu-casa.lan photos.tu-casa.lan media.tu-casa.lan
```

Consulta [docs/network.md](docs/network.md) para más opciones de red.

### 7. Desplegar el stack

```bash
bash scripts/prepare-compose.sh
bash scripts/up.sh
```

El script `up.sh` levanta primero MariaDB y PostgreSQL, espera a que estén listos, y luego arranca el resto. Esto evita errores de dependencias.

Verifica que todos los contenedores estén en ejecución:

```bash
docker compose ps
```

### 8. Configurar Tailscale (acceso remoto)

```bash
sudo tailscale up
```

Instala Tailscale en móvil y PC. Accede a los servicios con la IP Tailscale del NAS.

### 9. Confiar en el certificado de Caddy

Caddy genera certificados TLS internos. En el primer acceso, el navegador mostrará una advertencia. Para confiar en ellos:

1. Accede a `https://cloud.tu-casa.lan`
2. Exporta el certificado raíz de Caddy desde `${NAS_DATA_PATH}/docker/caddy/data/caddy/pki/authorities/local/root.crt`
3. Instálalo como autoridad de certificación de confianza en cada dispositivo

### 10. Configurar backups

Monta el disco USB de backup:

```bash
sudo mkdir -p /mnt/backup
sudo mount /dev/sdc1 /mnt/backup
```

Configura el cron diario:

```bash
bash scripts/setup-backup-cron.sh
```

Ejecuta un backup manual para verificar:

```bash
sudo bash scripts/backup-restic.sh
```

## Configuración de servicios

### Nextcloud

1. Abre `https://cloud.tu-casa.lan`
2. El administrador se crea automáticamente con las credenciales del `.env`
3. Activa **2FA** en Ajustes → Seguridad
4. Instala la app **Nextcloud** en móvil:
   - Android: [Google Play](https://play.google.com/store/apps/details?id=com.nextcloud.client)
   - iOS: [App Store](https://apps.apple.com/app/nextcloud/id1125420102)
5. Configura la URL del servidor y activa la subida automática de fotos

### Immich

1. Abre `https://photos.tu-casa.lan`
2. Crea la cuenta de administrador en el primer acceso
3. Activa **2FA** en Ajustes de cuenta
4. Instala la app **Immich** en móvil:
   - Android: [Google Play](https://play.google.com/store/apps/details?id=app.alextran.immich)
   - iOS: [App Store](https://apps.apple.com/app/immich/id1613940772)
5. En la app, activa **Backup automático** para subir fotos y vídeos en segundo plano

### Jellyfin

1. Abre `https://media.tu-casa.lan`
2. Completa el asistente de configuración inicial
3. Añade bibliotecas apuntando a:
   - Películas: `/media/movies`
   - Series: `/media/series`
   - Música: `/media/music`
4. Copia tus archivos multimedia al NAS:

```bash
cp -r /ruta/peliculas/* /srv/nas/media/movies/
```

5. Instala la app Jellyfin en TV/móvil para reproducir contenido

## Estructura del proyecto

```
MarkBase/
├── README.md
├── docker-compose.yml        # Stack completo de servicios
├── .env.example              # Plantilla de variables
├── caddy/
│   └── Caddyfile             # Reverse proxy HTTPS
├── scripts/
│   ├── install-docker.sh     # Instala Docker + Tailscale
│   ├── mount-data-disk.sh    # Monta disco de datos
│   ├── backup-restic.sh      # Backup diario
│   ├── setup-backup-cron.sh  # Programa el cron
│   ├── prepare-compose.sh    # Crea carpetas y valida .env
│   └── up.sh                 # Arranque por fases (BDs primero)
└── docs/
    ├── hardware.md           # Guía de hardware
    ├── network.md            # Red y acceso remoto
    └── restore.md            # Procedimiento de restauración
```

## Comandos útiles

```bash
# Ver estado de los servicios
docker compose ps

# Ver logs de un servicio
docker compose logs -f nextcloud
docker compose logs -f immich-server
docker compose logs -f jellyfin

# Reiniciar un servicio
docker compose restart nextcloud

# Actualizar imágenes
docker compose pull
docker compose up -d

# Backup manual
sudo bash scripts/backup-restic.sh

# Listar snapshots de backup
restic snapshots
```

## Copias de seguridad

Estrategia 3-2-1 simplificada:

1. **Copia en vivo**: datos en el HDD principal (`/srv/nas`)
2. **Copia local**: Restic diario a disco USB (`/mnt/backup/restic`)
3. **Copia off-site** (opcional): sync a Backblaze B2 cuando el presupuesto lo permita

Consulta [docs/restore.md](docs/restore.md) para el procedimiento de restauración completo.

## Seguridad

- Cambia todas las contraseñas por defecto del `.env`
- Activa 2FA en Nextcloud e Immich
- No abras puertos al router; usa Tailscale para acceso remoto
- Configura SSH con clave pública
- Mantén el sistema actualizado: `sudo apt update && sudo apt upgrade`

## Solución de problemas

### Error de dependencias (postgres / mariadb no listos)

Suele ocurrir si las bases de datos aún no han terminado de inicializarse. Usa el arranque por fases:

```bash
bash scripts/prepare-compose.sh
bash scripts/up.sh
```

Comprueba también:

1. Que existe `.env` (copiado desde `.env.example`)
2. Que las carpetas de datos existen (`NAS_DATA_PATH`, por defecto `/srv/nas`)
3. Los logs de las bases de datos:

```bash
docker compose logs mariadb
docker compose logs postgres
```

Si cambiaste la imagen de PostgreSQL y el contenedor crashea, borra el volumen corrupto (solo si es instalación nueva):

```bash
docker compose down
sudo rm -rf /srv/nas/docker/postgres/*
bash scripts/up.sh
```

### Los servicios no arrancan

```bash
docker compose logs --tail=50
```

Comprueba que `/srv/nas` está montado y que el `.env` tiene valores correctos.

### Nextcloud muestra error de dominio de confianza

Añade el dominio en el `.env`:

```
NEXTCLOUD_TRUSTED_DOMAINS=cloud.tu-casa.lan
```

Y reinicia: `docker compose restart nextcloud`

### Immich va lento al indexar fotos

En hardware modesto, la indexación ML puede tardar. Es normal. Considera desactivar temporalmente el reconocimiento facial en Ajustes → Machine Learning.

### Jellyfin no reproduce vídeos

Comprueba que los archivos están en `/srv/nas/media/` y que Jellyfin tiene permisos de lectura. Para 4K en hardware débil, activa solo **direct play** sin transcoding.

## Licencia

Uso personal. Los servicios incluidos (Nextcloud, Immich, Jellyfin, Caddy) tienen sus propias licencias.
