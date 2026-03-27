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
