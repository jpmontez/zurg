# Zurg Configuration Reference — v0.9

Source: https://github.com/debridmediamanager/zurg-testing/wiki/Config-v0.9
Fetched: 2026-03-27

---

## Overview

Zurg is a configuration system for organizing media library directory structures with Real-Debrid integration. The `config.yaml` file defines how torrents are categorized and filtered.

## Basic Configuration

```yaml
zurg: v1
token: YOUR_RD_API_TOKEN
host: "[::]"
port: 9999
```

### Core Settings

| Setting | Purpose | Default |
|---------|---------|---------|
| `token` | Real-Debrid API token | Required |
| `host` | Binding address | `[::]` (all interfaces) |
| `port` | Service port | `9999` |
| `username`/`password` | Optional authentication | - |
| `proxy` | Network proxy configuration | - |
| `concurrent_workers` | Worker thread count | 20 |
| `check_for_changes_every_secs` | Refresh interval | 15 seconds |

## File Handling Options

- `retain_rd_torrent_name`: Keep original Real-Debrid torrent names
- `retain_folder_name_extension`: Include file extensions in folder names
- `expose_full_path`: Include subfolders in file paths
- `auto_delete_rar_torrents`: Remove unplayable RAR archives
- `enable_repair`: Attempt torrent repair (one instance only)
- `serve_from_rclone`: Delegate downloads to rclone
- `verify_download_link`: Pre-verify links before passing to rclone
- `force_ipv6`: Use only IPv6 connections
- `network_buffer_size`: Default 32KB (32768 bytes)

## Network & API Settings

- `rate_limit_sleep_secs`: Pause duration after HTTP 429 responses
- `api_timeout_secs`: Real-Debrid API response timeout
- `download_timeout_secs`: File download response timeout
- `retries_until_failed`: Maximum retry attempts

## Directory Configuration

Directories organize torrents into logical groups:

```yaml
directories:
  anime:
    group: media
    group_order: 10
    filters:
      - regex: /\b[a-fA-F0-9]{8}\b/
```

### Directory Properties

- `group`: Logical category (prevents duplicate torrents across same group)
- `group_order`: Priority within group (lower = higher priority)
- `filters`: Matching conditions
- `only_show_the_biggest_file`: Display single largest file only
- `only_show_files_with_size_lte`: Maximum file size threshold
- `only_show_files_with_size_gte`: Minimum file size threshold

## Filter Types

### Basic Filters

- `id`: Match torrent identifier
- `regex`/`not_regex`: Pattern matching
- `contains`/`not_contains`: Substring search (case-insensitive)
- `contains_strict`/`not_contains_strict`: Case-sensitive substring search

### File-Level Filters

- `any_file_inside_regex`: Pattern match on filenames
- `any_file_inside_not_regex`: Exclude pattern matches
- `any_file_inside_contains`: Substring in any filename
- `any_file_inside_not_contains`: Exclude substring from filenames
- `any_file_inside_contains_strict`: Case-sensitive filename search
- `any_file_inside_not_contains_strict`: Case-sensitive exclusion

### Size Filters

- `size_gte`/`size_lte`: Torrent size thresholds (bytes)
- `any_file_inside_size_gte`/`any_file_inside_size_lte`: Individual file size limits

### Content Detection

- `has_episodes`: Identifies torrents with episode sequences

## Advanced Filtering

Combine conditions using logical operators:

```yaml
filters:
  - and:
    - has_episodes: true
    - any_file_inside_regex: /^\[/
    - any_file_inside_not_regex: /s\d\de\d\d/i
  - or:
    - contains: keyword1
    - regex: /pattern/i
```

### Regex Flags

- `i`: Case-insensitive matching
- `x`: Extended mode (whitespace and comments allowed)

## Library Update Trigger

Execute scripts when content changes:

```yaml
on_library_update: sh plex_update.sh "$@"
```

## Important Considerations

1. **`any_file_inside_*` Behavior**: Filters matching any filename can unexpectedly combine files from multiple torrents when one matches and another doesn't.

2. **`not_contains` in `or` Context**: Using negation operators within `or` conditions alongside positive matchers may include unintended torrents.

3. **Filter Testing**: Test configurations thoroughly to ensure intended behavior.
