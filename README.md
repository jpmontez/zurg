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
   curl -X PROPFIND http://localhost:9999/dav/ -H "Depth: 0" -s -o /dev/null -w "%{http_code}"
   ```
   Expected: `207`

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
