# Hardware — NAS casero de bajo presupuesto

Guía para elegir y preparar el hardware del servidor NAS.

## Opciones recomendadas

### Opción A — PC viejo o portátil (recomendada)

La mejor relación calidad/precio si ya tienes hardware disponible.

| Componente | Mínimo | Recomendado |
|---|---|---|
| CPU | Intel i3 / AMD equivalente (4ª gen+) | Intel i5 / Ryzen 3 |
| RAM | 8 GB | 16 GB |
| Disco sistema | SSD 128 GB | SSD 256 GB |
| Disco datos | HDD 4 TB | 2× HDD 4 TB (mirror) |
| Red | Gigabit Ethernet | Gigabit Ethernet |

### Opción B — Mini PC dedicado

Si no tienes PC viejo:

- **Intel N100 / N305** (~120-180 €)
- SSD interno 256 GB para SO + Docker
- HDD externo USB 3.0 o bahía SATA para datos

## Lista de compra orientativa

| Componente | Cantidad | Uso | Coste aprox. |
|---|---|---|---|
| PC viejo / mini PC | 1 | Servidor | 0-180 € |
| SSD 256 GB | 1 | SO + contenedores | 20-30 € |
| HDD 4 TB (WD Red / IronWolf) | 1-2 | Datos | 80-90 €/u. |
| HDD USB 4 TB | 1 (opcional) | Backup offline | 80-90 € |
| Cable Ethernet Cat6 | 1 | Conexión al router | 5-10 € |
| UPS básica | 1 (opcional) | Protección cortes | ~40 € |

**Total mínimo**: ~100-120 € (solo discos + PC existente)  
**Total recomendado**: ~200-280 € (mini PC + 2 HDD)

## Configuración de almacenamiento

### Un solo disco

Montar en `/srv/nas` y priorizar copias externas con Restic.

### Dos discos iguales (RAID1 mirror)

```bash
# Crear mirror con mdadm (ejemplo /dev/sdb y /dev/sdc)
sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sdb /dev/sdc
sudo mkfs.ext4 /dev/md0
```

O con ZFS (requiere `zfsutils-linux`):

```bash
sudo zpool create nas mirror /dev/sdb /dev/sdc
sudo zfs set mountpoint=/srv/nas nas
```

## Ubicación física

- Lugar ventilado, lejos de fuentes de calor
- Preferiblemente fuera del dormitorio (ruido de discos)
- Conexión Ethernet directa al router (evitar Wi-Fi como única conexión)
- Consumo estimado: 15-40 W (PC viejo) / 6-15 W (mini PC)

## Checklist antes de instalar el SO

- [ ] SSD instalado y detectado en BIOS/UEFI
- [ ] HDD(s) de datos conectados y detectados
- [ ] Cable Ethernet conectado
- [ ] USB de instalación de Debian/Ubuntu creado
- [ ] IP fija reservada en el router (anotar MAC del servidor)
