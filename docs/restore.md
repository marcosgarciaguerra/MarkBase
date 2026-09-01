# Procedimiento de restauración

Guía para recuperar datos desde copias Restic en caso de fallo del disco o del servidor.

## Requisitos previos

- Disco USB con repositorio Restic montado
- Contraseña del repositorio (`RESTIC_PASSWORD` del `.env`)
- Restic instalado en el sistema de restauración

```bash
sudo apt install restic
```

## Listar snapshots disponibles

```bash
export RESTIC_REPOSITORY=/mnt/backup/restic
export RESTIC_PASSWORD="tu_contraseña"

restic snapshots
```

Salida esperada:

```
ID        Time                 Host        Tags        Paths
----------------------------------------------------------------
a1b2c3d4  2026-09-01 03:00:01  nas         daily       /backups
e5f6g7h8  2026-08-31 03:00:01  nas         daily       /backups
```

## Restaurar todo

```bash
# Crear directorio de destino
sudo mkdir -p /srv/nas/restore

# Restaurar el snapshot más reciente
restic restore latest --target /srv/nas/restore
```

## Restaurar un snapshot específico

```bash
restic restore a1b2c3d4 --target /srv/nas/restore
```

## Restaurar solo un directorio

```bash
# Solo archivos de Nextcloud
restic restore latest --target /srv/nas/restore --include /backups/nextcloud-data

# Solo base de datos de Immich
restic restore latest --target /srv/nas/restore --include /backups/immich-db
```

## Restaurar bases de datos

Tras restaurar los dumps SQL:

### MariaDB (Nextcloud)

```bash
cd /srv/nas/restore/backups/mariadb
gunzip -c latest.sql.gz | docker exec -i nas-mariadb mysql -u root -p"${MYSQL_ROOT_PASSWORD}"
```

### PostgreSQL (Immich)

```bash
cd /srv/nas/restore/backups/postgres
gunzip -c latest.sql.gz | docker exec -i nas-postgres psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}"
```

## Restaurar volúmenes de datos

```bash
# Nextcloud
sudo rsync -av /srv/nas/restore/backups/nextcloud-data/ /srv/nas/nextcloud/

# Immich
sudo rsync -av /srv/nas/restore/backups/immich-library/ /srv/nas/immich/

# Media
sudo rsync -av /srv/nas/restore/backups/media/ /srv/nas/media/
```

## Reiniciar servicios

```bash
cd ~/MarkBase
docker compose down
docker compose up -d
```

## Verificar integridad del repositorio

Ejecutar periódicamente (o tras un fallo sospechoso):

```bash
restic check
restic check --read-data
```

## Prueba de restauración recomendada

Realizar una vez al mes:

1. Montar disco USB de backup
2. Restaurar un archivo pequeño a `/tmp/restore-test`
3. Verificar que el contenido es correcto
4. Documentar la fecha de la prueba
