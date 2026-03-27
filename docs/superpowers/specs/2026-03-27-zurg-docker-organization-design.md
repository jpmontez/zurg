# Zurg Docker Organization Design

**Date:** 2026-03-27
**Status:** Approved

## Goal

Reorganize the zurg deployment repository for local and home network usage. Replace the scattered multi-service Docker Compose setup with a minimal single-container configuration using WebDAV for direct media access. Remove unused components (rclone, Plex scripts, systemd files). Ensure no secrets are checked into version control.

## Context

The existing repo uses `ghcr.io/debridmediamanager/zurg-testing:latest` as a pre-built Docker image for a zurg + rclone two-container setup. On macOS and Windows with Docker Desktop, FUSE mounts inside containers do not expose to the host filesystem, making rclone's mount mode non-functional. Direct WebDAV access is simpler, cross-platform, and requires no FUSE or elevated container privileges.

## Architecture

```
Real-Debrid API
      ↓
┌─────────────────────────┐
│  zurg container (:9999) │
│  WebDAV at /dav         │
└─────────────────────────┘
      ↓
http://localhost:9999/dav        ← same machine
http://<local-ip>:9999/dav       ← home WiFi devices
http://<tailscale-ip>:9999/dav   ← remote via Tailscale
```

No rclone. No FUSE. No Plex integration.

## Repository Structure

```
zurg/
├── .env                          # gitignored — RD_TOKEN=yourtoken
├── .env.example                  # checked in — RD_TOKEN=
├── .gitignore                    # ensures .env is never committed
├── config.yml                    # zurg config, token via ${ZURG_TOKEN}
├── docker-compose.yml            # single zurg service
├── docs/
│   ├── config-v0.9.md            # zurg wiki config reference (local copy)
│   ├── network-access.md         # local WiFi + Tailscale access guide
│   └── superpowers/specs/        # design documents
└── CLAUDE.md
```

**Deleted:** `rclone.conf`, `scripts/`, `lib/`

## Files

### docker-compose.yml

```yaml
services:
  zurg:
    image: ghcr.io/debridmediamanager/zurg-testing:latest
    container_name: zurg
    restart: unless-stopped
    ports:
      - "9999:9999"
    volumes:
      - ./config.yml:/app/config.yml
      - zurgdata:/app/data
    environment:
      - ZURG_TOKEN=${RD_TOKEN}

volumes:
  zurgdata:
```

The named volume `zurgdata` persists zurg's internal state (torrent cache, repair data) across restarts. Use `docker compose down` (not `docker compose down -v`) to avoid destroying the volume accidentally.

Token flow: `.env` → Compose reads `RD_TOKEN` → passes into container as `ZURG_TOKEN` environment variable → zurg reads `${ZURG_TOKEN}` from its own process environment when parsing `config.yml` at startup. This is runtime interpolation by the zurg process itself, not Docker Compose file interpolation.

### config.yml

```yaml
zurg: v1
token: ${ZURG_TOKEN}

check_for_changes_every_secs: 10
enable_repair: true
auto_delete_rar_torrents: true

directories:
  anime:
    group_order: 10
    group: media
    filters:
      - regex: /\b[a-fA-F0-9]{8}\b/
      - any_file_inside_regex: /\b[a-fA-F0-9]{8}\b/

  shows:
    group_order: 20
    group: media
    filters:
      - has_episodes: true

  movies:
    group_order: 30
    group: media
    only_show_the_biggest_file: true
    filters:
      - regex: /.*/
```

`zurg: v1` is the required config schema version field — it must be present and set to `v1` for this version of zurg. Directory filters should be tuned after first run. See `docs/config-v0.9.md` for the full config reference.

### .env.example

```
RD_TOKEN=
```

### .gitignore additions

```
.env
```

After updating `.gitignore`, verify the file is excluded before committing:
```
git check-ignore -v .env
```
This must return a match. If it does not, the token will be committed.

## Secret Handling

- Real-Debrid token stored only in `.env` (gitignored)
- `.env.example` checked in as template with empty value
- `config.yml` uses `${ZURG_TOKEN}` — zurg interpolates this from its container environment at startup
- No secrets ever committed to version control

## Cross-Platform Compatibility

This setup runs identically on macOS and Windows 11 via Docker Desktop. No FUSE, no `SYS_ADMIN` capability, no Linux-only devices required.

## Network Access

### Same Machine
- `http://localhost:9999/dav`

### Local WiFi
- Find host IP:
  - macOS: `ipconfig getifaddr en0` (or `en1` for WiFi)
  - Windows: `ipconfig` → look for IPv4 Address under the active adapter
- Access from any device on the same network: `http://<host-ip>:9999/dav`
- Mount natively:
  - **macOS**: Finder → Go → Connect to Server → `http://<host-ip>:9999/dav`
  - **Windows**: Open File Explorer → Map Network Drive → enter `http://<host-ip>:9999/dav` in the folder field. The `\\server@port\path` UNC syntax requires the WebClient service and is unreliable; use the `http://` form instead.

### Remote Access via Tailscale
- Install Tailscale on the host machine and on the remote Windows 11 device
- Both must be signed into the same Tailscale account
- Find host's Tailscale IP in the Tailscale app (e.g., `100.x.x.x`)
- Access: `http://100.x.x.x:9999/dav`
- Alternatives: ZeroTier or self-hosted WireGuard are equivalent options

## Implementation Steps

1. Delete `rclone.conf`, `scripts/`, `lib/`
2. Update `docker-compose.yml` — single zurg service with env var injection
3. Update `config.yml` — replace hardcoded token with `${ZURG_TOKEN}`, remove `on_library_update`
4. Add `.env` with `RD_TOKEN=<token>` and `.env.example` with `RD_TOKEN=`
5. Update `.gitignore` to exclude `.env`; verify with `git check-ignore -v .env`
6. Save wiki config reference to `docs/config-v0.9.md` (source: https://github.com/debridmediamanager/zurg-testing/wiki/Config-v0.9)
7. Write `docs/network-access.md` with local WiFi and Tailscale instructions
8. Update `CLAUDE.md` to reflect new structure
9. Start the container: `docker compose up -d`
10. Verify WebDAV is live: `curl -I http://localhost:9999/dav` — expect HTTP 200 or 207
