# Zurg Docker Organization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorganize the zurg repo into a minimal single-container Docker Compose setup with WebDAV-only access, secret injection via `.env`, and supporting documentation.

**Architecture:** The zurg container (`ghcr.io/debridmediamanager/zurg-testing:latest`) serves WebDAV at port 9999. Docker Compose reads `RD_TOKEN` from a gitignored `.env` file and passes it into the container as `ZURG_TOKEN`. `config.yml` references `${ZURG_TOKEN}`, which zurg interpolates from its own process environment at startup. No rclone, no FUSE, no Plex.

**Tech Stack:** Docker Desktop, Docker Compose v2, zurg v0.9.3

---

### Task 1: Remove unused files

**Files:**
- Delete: `rclone.conf`
- Delete: `scripts/plex_update.sh`
- Delete: `scripts/plex_update.ps1`
- Delete: `lib/systemd/system/zurg.service`
- Delete: `lib/systemd/system/zurg-rclone.service`

- [ ] **Step 1: Delete all unused files and directories**

```bash
git rm rclone.conf
git rm scripts/plex_update.sh
git rm scripts/plex_update.ps1
git rm lib/systemd/system/zurg.service
git rm lib/systemd/system/zurg-rclone.service
git rm -r '$HOME'
```

Note: `'$HOME'` uses single quotes to target the literal directory named `$HOME` at the repo root — not the shell variable. This directory contains a misplaced rclone config (`$HOME/.config/rclone/rclone.conf`) that was accidentally committed and must be removed.

- [ ] **Step 2: Verify all six paths are staged for deletion**

```bash
git status
```

Expected: all six paths listed under "Changes to be committed" as deleted, including `$HOME/.config/rclone/rclone.conf`. The `scripts/`, `lib/`, and `$HOME/` directories will disappear automatically — git does not track empty directories.

- [ ] **Step 3: Commit**

```bash
git commit -m "chore: remove rclone, plex scripts, and systemd files"
```

---

### Task 2: Add .gitignore and secret files

**Files:**
- Create: `.gitignore`
- Create: `.env.example`
- Create: `.env` (local only — never committed)

- [ ] **Step 1: Create `.gitignore`**

```
.env
```

- [ ] **Step 2: Create `.env.example`**

```
RD_TOKEN=
```

- [ ] **Step 3: Create `.env` with your actual token**

```
RD_TOKEN=your_real_debrid_token_here
```

Replace `your_real_debrid_token_here` with your actual Real-Debrid API token from https://real-debrid.com/apitoken.

- [ ] **Step 4: Verify `.env` is gitignored**

```bash
git check-ignore -v .env
```

Expected output (the path must match):
```
.gitignore:1:.env	.env
```

If this returns nothing, `.env` is NOT excluded — stop and fix `.gitignore` before proceeding.

- [ ] **Step 5: Commit `.gitignore` and `.env.example` only**

```bash
git add .gitignore .env.example
git status
```

Confirm `.env` does NOT appear in the output. Then:

```bash
git commit -m "chore: add .gitignore and .env.example for secret management"
```

---

### Task 3: Update docker-compose.yml

**Files:**
- Modify: `docker-compose.yml`

- [ ] **Step 1: Replace `docker-compose.yml` contents**

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

- [ ] **Step 2: Verify the file looks correct**

```bash
cat docker-compose.yml
```

Confirm: no rclone service, no `version:` key (Compose v2 doesn't need it), `ZURG_TOKEN=${RD_TOKEN}` in environment.

- [ ] **Step 3: Commit**

```bash
git add docker-compose.yml
git commit -m "chore: simplify docker-compose to single zurg service with env token"
```

---

### Task 4: Update config.yml

**Files:**
- Modify: `config.yml`

- [ ] **Step 1: Replace `config.yml` contents**

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

Key changes from original:
- `token: yourtoken` → `token: ${ZURG_TOKEN}` (env var, read by zurg at startup)
- `on_library_update` line removed (Plex hook no longer used)
- All commented-out lines removed (see `docs/config-v0.9.md` for full reference)

- [ ] **Step 2: Verify no hardcoded token**

```bash
grep -n "token" config.yml
```

Expected:
```
2:token: ${ZURG_TOKEN}
```

If your actual token appears anywhere in the output, fix it before committing.

- [ ] **Step 3: Commit**

```bash
git add config.yml
git commit -m "chore: replace hardcoded token with env var, remove plex hook"
```

---

### Task 5: Save wiki config reference locally

**Files:**
- Create: `docs/config-v0.9.md`

- [ ] **Step 1: Fetch the wiki page**

```bash
curl -sL "https://raw.githubusercontent.com/wiki/debridmediamanager/zurg-testing/Config-v0.9.md" -o docs/config-v0.9.md
```

If that URL returns empty or 404, use the WebFetch tool on `https://github.com/debridmediamanager/zurg-testing/wiki/Config-v0.9` and write the result to `docs/config-v0.9.md`.

Prepend this header to the file:

```markdown
# Zurg Configuration Reference — v0.9

Source: https://github.com/debridmediamanager/zurg-testing/wiki/Config-v0.9
Fetched: 2026-03-27

---

```

- [ ] **Step 2: Verify the file is non-empty and contains config content**

```bash
wc -l docs/config-v0.9.md
grep -c "token" docs/config-v0.9.md
```

Expected: line count > 10, and at least one match for "token". If the file is empty or missing, the fetch failed — retry using the WebFetch tool.

- [ ] **Step 3: Commit**

```bash
git add docs/config-v0.9.md
git commit -m "docs: save zurg config v0.9 wiki reference locally"
```

---

### Task 6: Write network access documentation

**Files:**
- Create: `docs/network-access.md`

- [ ] **Step 1: Create `docs/network-access.md`** with the following content:

```markdown
# Network Access Guide

Zurg serves WebDAV at port 9999. You can access it from the same machine, any device on your home WiFi, or remotely via Tailscale.

## Same Machine

```
http://localhost:9999/dav
```

## Home WiFi (Local Network)

Find the host machine's local IP:

- **macOS:** `ipconfig getifaddr en0` (try `en1` if that returns nothing — en1 is usually WiFi)
- **Windows:** Run `ipconfig` in Command Prompt, look for "IPv4 Address" under your active network adapter

Access from any device on the same WiFi:
```
http://<host-ip>:9999/dav
```

### Mount as a network drive

**macOS:** Finder → Go → Connect to Server → enter `http://<host-ip>:9999/dav`

**Windows:** Open File Explorer → right-click "This PC" → "Map network drive" → in the Folder field enter:
```
http://<host-ip>:9999/dav
```
Use the `http://` form, not the `\\server@port\path` UNC form — the UNC form requires the WebClient service and is unreliable on Windows 11.

## Remote Access via Tailscale

Tailscale creates an encrypted peer-to-peer overlay network — no port forwarding required.

1. Install Tailscale on the host machine: https://tailscale.com/download
2. Install Tailscale on the remote device (Windows 11, phone, etc.)
3. Sign both into the same Tailscale account
4. Open the Tailscale app on the host and note its Tailscale IP (format: `100.x.x.x`)
5. Access from anywhere:
   ```
   http://100.x.x.x:9999/dav
   ```

### Alternatives to Tailscale

- **ZeroTier** (https://zerotier.com) — similar mesh VPN, slightly more complex setup
- **WireGuard** — self-hosted, requires a VPS or static IP as the relay, higher setup effort but no third-party dependency
```

- [ ] **Step 2: Verify the file was created**

```bash
wc -l docs/network-access.md
grep -c "Tailscale" docs/network-access.md
```

Expected: line count > 20, at least one match for "Tailscale".

- [ ] **Step 3: Commit**

```bash
git add docs/network-access.md
git commit -m "docs: add network access guide for local and remote WebDAV"
```

---

### Task 7: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Replace `CLAUDE.md` contents**

```markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

A deployment configuration repository for **Zurg**, a self-hosted Real-Debrid WebDAV server. This repo contains no Go source code — the upstream binary is pulled via the Docker image `ghcr.io/debridmediamanager/zurg-testing`.

**Architecture:**
```
Real-Debrid API → Zurg container (:9999) → WebDAV at http://localhost:9999/dav
```

No rclone. No FUSE. WebDAV is accessed directly by media apps or mounted as a network drive.

## Setup

1. Copy `.env.example` to `.env` and add your Real-Debrid token: `RD_TOKEN=yourtoken`
2. `docker compose up -d`
3. Verify: `curl -I http://localhost:9999/dav` — expect HTTP 200 or 207

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
| `docker-compose.yml` | Single zurg service, injects `ZURG_TOKEN` from `.env` |
| `.env` | Gitignored — holds `RD_TOKEN=yourtoken` |
| `.env.example` | Checked-in template with empty `RD_TOKEN=` |
| `docs/config-v0.9.md` | Full config reference (local copy of upstream wiki) |
| `docs/network-access.md` | How to access WebDAV on LAN and remotely via Tailscale |

## Secret Handling

The Real-Debrid token lives only in `.env` (gitignored). `config.yml` reads it as `${ZURG_TOKEN}` — zurg interpolates this from its container environment at startup. Never hardcode the token in `config.yml`.

## Network Access

- Same machine: `http://localhost:9999/dav`
- Home WiFi: `http://<host-local-ip>:9999/dav`
- Remote (Tailscale): `http://<tailscale-ip>:9999/dav`

See `docs/network-access.md` for full instructions.
```

- [ ] **Step 2: Verify the file was updated correctly**

```bash
grep "ZURG_TOKEN" CLAUDE.md
grep "rclone" CLAUDE.md
```

Expected: at least one match for "ZURG_TOKEN". Expected: zero matches for "rclone" (it has been removed from the setup).

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md for single-container WebDAV setup"
```

---

### Task 8: Update README.md

**Files:**
- Modify: `README.md`

The existing `README.md` describes the old two-container rclone/Plex setup. It must be updated to reflect the new single-container WebDAV-only setup, or readers will follow outdated instructions.

- [ ] **Step 1: Replace `README.md` contents**

```markdown
# zurg

Self-hosted [Real-Debrid](https://real-debrid.com) WebDAV server, running as a single Docker container.

## Quick Start

1. Copy `.env.example` to `.env` and add your Real-Debrid API token:
   ```
   RD_TOKEN=your_token_here
   ```
   Get your token from https://real-debrid.com/apitoken

2. Start the container:
   ```bash
   docker compose up -d
   ```

3. Verify it's running:
   ```bash
   curl -I http://localhost:9999/dav
   ```
   Expected: `HTTP/1.1 200 OK` or `207 Multi-Status`

## Accessing Your Library

- **Same machine:** `http://localhost:9999/dav`
- **Home network:** `http://<host-ip>:9999/dav`
- **Remote (Tailscale):** `http://<tailscale-ip>:9999/dav`

See `docs/network-access.md` for full instructions including native drive mounting on macOS and Windows.

## Configuration

Edit `config.yml` to adjust directory filters and polling settings. See `docs/config-v0.9.md` for the full config reference.

After editing `config.yml`, restart the container:
```bash
docker compose restart zurg
```

**Never run `docker compose down -v`** — this destroys the `zurgdata` volume (torrent cache and repair state).

## Upstream

Binary: [debridmediamanager/zurg-testing](https://github.com/debridmediamanager/zurg-testing)
```

- [ ] **Step 2: Verify the file looks correct**

```bash
grep -c "RD_TOKEN" README.md
grep "rclone" README.md
```

Expected: at least one match for `RD_TOKEN`, zero matches for `rclone`.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: rewrite README for single-container WebDAV setup"
```

---

### Task 9: Start and verify

- [ ] **Step 1: Confirm repo is clean before starting**

```bash
git status
```

Expected: `nothing to commit, working tree clean`. If there are uncommitted changes, investigate and commit or discard them before proceeding. Running Docker with uncommitted config changes can make it hard to know which state the container is running.

- [ ] **Step 2: Pull the latest image**

```bash
docker compose pull
```

- [ ] **Step 3: Start the container**

```bash
docker compose up -d
```

Expected: zurg container starts, no errors.

- [ ] **Step 4: Check logs for startup errors**

```bash
docker compose logs zurg
```

Look for a line indicating zurg has started and is listening on port 9999. If you see token-related errors, verify `.env` contains the correct `RD_TOKEN` value.

- [ ] **Step 5: Verify WebDAV endpoint is live**

```bash
curl -I http://localhost:9999/dav
```

Expected: `HTTP/1.1 200 OK` or `HTTP/1.1 207 Multi-Status`. Any 2xx or 207 response means WebDAV is up.

- [ ] **Step 6: Browse the WebDAV directory listing**

```bash
curl http://localhost:9999/dav
```

Expected: HTML or XML listing your Real-Debrid library organized into `anime`, `shows`, `movies` directories. If the directories appear empty or missing, the token is likely wrong — check `docker compose logs zurg` for auth errors.
