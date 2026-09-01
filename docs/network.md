# Red y acceso remoto

Configuración de red local y acceso seguro desde fuera de casa.

## IP fija en el router

1. Accede al panel de administración del router (normalmente `192.168.1.1` o `192.168.0.1`)
2. Busca **DHCP Reservation** / **Reserva de dirección**
3. Asigna una IP fija al NAS usando su dirección MAC
4. Ejemplo: `192.168.1.100` → NAS

## DNS local

### Opción A — Router con DNS local

Si tu router lo permite, crea registros DNS:

| Host | IP | Servicio |
|---|---|---|
| `cloud.tu-casa.lan` | 192.168.1.100 | Nextcloud |
| `photos.tu-casa.lan` | 192.168.1.100 | Immich |
| `media.tu-casa.lan` | 192.168.1.100 | Jellyfin |

### Opción B — Archivo hosts (Windows)

Editar `C:\Windows\System32\drivers\etc\hosts` como administrador:

```
192.168.1.100  cloud.tu-casa.lan
192.168.1.100  photos.tu-casa.lan
192.168.1.100  media.tu-casa.lan
```

### Opción C — Archivo hosts (Linux/macOS)

Editar `/etc/hosts`:

```
192.168.1.100  cloud.tu-casa.lan photos.tu-casa.lan media.tu-casa.lan
```

## Firewall (UFW)

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.0.0/16 to any port 22    # SSH desde LAN
sudo ufw allow from 192.168.0.0/16 to any port 80    # HTTP
sudo ufw allow from 192.168.0.0/16 to any port 443   # HTTPS
sudo ufw allow in on tailscale0                        # Tailscale
sudo ufw enable
```

Ajusta el rango de red si tu LAN usa otra subred (ej. `10.0.0.0/8`).

## Tailscale — acceso remoto

Tailscale crea una VPN mesh sin abrir puertos en el router.

### Instalación en el NAS

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Anota la IP Tailscale del NAS (ej. `100.x.x.x`).

### Acceso desde fuera de casa

1. Instala Tailscale en móvil/PC: https://tailscale.com/download
2. Inicia sesión con la misma cuenta
3. Accede a los servicios con la IP Tailscale:

```
https://100.x.x.x  (Caddy responde según el header Host)
```

O configura MagicDNS en Tailscale para usar nombres como `nas.tailnet-name.ts.net`.

### Reglas de seguridad

- **No abras** puertos 22, 80 ni 443 en el router hacia internet
- Usa 2FA en Nextcloud e Immich
- SSH solo con clave pública (deshabilitar login por contraseña)

## Puertos internos (solo Docker)

| Servicio | Puerto interno | Expuesto vía |
|---|---|---|
| Caddy | 80, 443 | Sí (proxy) |
| Nextcloud | 8080 | Solo Caddy |
| Immich | 2283 | Solo Caddy |
| Jellyfin | 8096 | Solo Caddy |
| MariaDB | 3306 | No |
| PostgreSQL | 5432 | No |
| Redis | 6379 | No |
