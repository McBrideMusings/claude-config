# Caddy Reverse Proxy Management — Unraid Plugin

## Network Architecture

All services are **Tailnet-only**. There are two access methods, both restricted to the Tailscale network:

1. **Caddy reverse proxy:** `https://servicename.piercetower.local` — CoreDNS (also an Unraid plugin) provides split DNS on the Tailnet, resolving `*.piercetower.local` to `100.114.249.118` (Tailscale IP). Caddy terminates TLS on `:443` and proxies to the service.
2. **Direct Tailscale access:** `http://100.114.249.118:PORT` — access the container port directly over the Tailnet.

Both methods must work. Containers need **two** port bindings in their Docker templates:
- `100.114.249.118:PORT` — for direct Tailscale access
- `127.0.0.1:PORT` — for Caddy to proxy to (Arr apps use this for auth bypass)

## Setup Overview

Caddy runs as an **Unraid plugin** (not a Docker container).

- **Binary:** `/usr/local/bin/caddy`
- **Caddyfile:** `/boot/config/plugins/caddy-server/Caddyfile` (persistent across reboots)
- **Plugin dir:** `/boot/config/plugins/caddy-server/`
- **Admin API:** `127.0.0.1:2019`
- **Listening on:** `100.114.249.118:443` (Tailscale IP only)
- **TLS:** `tls internal` (Caddy internal CA, cert at `/boot/config/plugins/caddy-server/caddy-root-ca.crt`)
- **Domain pattern:** `*.piercetower.local`
- **Global option:** `auto_https disable_redirects`

## Caddyfile Organization

The Caddyfile is organized into labeled sections. When adding a new site, place it in the appropriate section:

```
# Public
# Core
# Arrs
# AI
# Services
# Dev
# Analytics
# IPTV
```

## Reverse Proxy Patterns

### 1. Simple proxy (most services)
Caddy proxies to the Tailscale IP binding. Direct access also works via `http://100.114.249.118:PORT`.
```caddy
servicename.piercetower.local {
    bind 100.114.249.118
    reverse_proxy http://100.114.249.118:PORT
    tls internal
}
```

### 2. Arr apps (Sonarr, Radarr, Prowlarr, Whisparr) — localhost with auth bypass
Caddy proxies to the localhost binding with `X-Forwarded-For 127.0.0.1` so Arr apps bypass authentication for the reverse proxy. Direct Tailscale access (`http://100.114.249.118:PORT`) still works and will prompt for login.
```caddy
arrname.piercetower.local {
    bind 100.114.249.118
    reverse_proxy http://127.0.0.1:PORT {
        header_up X-Forwarded-For 127.0.0.1
    }
    tls internal
}
```

### 3. Streaming/SSE proxy (needs flush for real-time data)
```caddy
servicename.piercetower.local {
    bind 100.114.249.118
    reverse_proxy http://100.114.249.118:PORT {
        flush_interval -1
    }
    tls internal
}
```

### 4. External/upstream proxy with TLS
```caddy
servicename.piercetower.local {
    bind 100.114.249.118
    reverse_proxy https://REMOTE_IP:443 {
        header_up Host servicename.piercetower.local
        transport http {
            tls_server_name some.hostname
        }
    }
    tls internal
}
```

## Procedures

### Adding a new reverse proxy entry
1. Edit `/boot/config/plugins/caddy-server/Caddyfile`
2. Add the site block in the appropriate section
3. Validate: `caddy validate --config /boot/config/plugins/caddy-server/Caddyfile`
4. Reload: `caddy reload --config /boot/config/plugins/caddy-server/Caddyfile`

### Debugging a 502 Bad Gateway
1. Check if the upstream service is actually listening on the expected IP:port: `ss -tlnp | grep PORT`
2. Common cause: the Docker container is missing a `127.0.0.1` port binding when the Caddyfile proxies to `127.0.0.1`
3. Fix by adding the localhost binding to the Docker template XML and recreating the container

### Important rules
- **Always validate before reloading.** Never reload without validating first.
- **Always reload, never restart**, unless there's a specific reason (e.g. binary upgrade).
- **Never edit the global block** `{ auto_https disable_redirects }` without asking the user.
- All sites **must** include `bind 100.114.249.118` and `tls internal`.
- Services must be accessible **both** via Caddy (`https://name.piercetower.local`) and directly via Tailscale IP+port. Never remove the Tailscale IP port binding from a container.
