# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

A deployment configuration repository for **Zurg**, a self-hosted Real-Debrid WebDAV server. This repo contains no Go source code — the upstream binary is pulled via the Docker image `ghcr.io/debridmediamanager/zurg-testing`, pinned to `v1.0.0` in `docker-compose.yml`. (The image keeps the `zurg-testing` name even though the upstream repo is now `zurg-public`.)

**Architecture:**
```
Real-Debrid API → Zurg container (:9999) → WebDAV at http://localhost:9999/dav
```

No rclone. No FUSE. WebDAV is accessed directly by media apps or mounted as a network drive.

## Setup

1. Copy `.env.example` to `.env` and add your Real-Debrid token: `RD_TOKEN=yourtoken`
2. `docker compose up -d`
3. Verify: `curl -X PROPFIND http://localhost:9999/dav/ -H "Depth: 0" -s -o /dev/null -w "%{http_code}"` — expect `207`

## Common Commands

```bash
# Start
docker compose up -d

# Restart after config.yml changes
docker compose restart zurg

# Logs
docker compose logs -f zurg

# Stop (preserves zurgdata volume)
docker compose down
```

**Never run `docker compose down -v`** — this destroys the `zurgdata` volume which holds zurg's torrent cache and repair state.

## Key Files

| File | Purpose |
|------|---------|
| `config.yml` | Zurg config — token via `${ZURG_TOKEN}`, directory filters, polling interval |
| `docker-compose.yml` | Single zurg service, injects `ZURG_TOKEN` from `.env`, uses custom entrypoint |
| `entrypoint.sh` | Substitutes `${ZURG_TOKEN}` in config.yml via `sed` before starting zurg |
| `.env` | Gitignored — holds `RD_TOKEN=yourtoken` |
| `.env.example` | Checked-in template with empty `RD_TOKEN=` |
| `docs/config-v0.9.md` | Full config reference (local copy of upstream wiki) |
| `docs/network-access.md` | How to access WebDAV on LAN and remotely via Tailscale |

## Secret Handling

The Real-Debrid token lives only in `.env` (gitignored). Docker Compose injects it as `ZURG_TOKEN` into the container. `entrypoint.sh` runs `sed` to substitute `${ZURG_TOKEN}` in `config.yml` before zurg starts — zurg itself does not support env var expansion in its config. Never hardcode the token in `config.yml`.

## Network Access

- Same machine: `http://localhost:9999/dav`
- Home WiFi: `http://<host-local-ip>:9999/dav`
- Remote (Tailscale): `http://<tailscale-ip>:9999/dav`

See `docs/network-access.md` for full instructions.
