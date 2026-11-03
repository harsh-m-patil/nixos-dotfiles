"""Per-transcript-file memoization (size + mtime), like T3 warm usage scans."""

from __future__ import annotations

import json
import os
import time
from pathlib import Path

CACHE_VERSION = 1
RETENTION_DAYS = 92
MTIME_SLACK_MS = 36 * 60 * 60 * 1000

_file_cache: dict[str, dict] | None = None
_dirty = False


def _cache_path() -> Path:
    home = os.environ.get("HOME", "~")
    return Path(home).expanduser() / ".config" / "quickshell" / "usage-transcript-cache.json"


def _load_disk_cache() -> dict[str, dict]:
    path = _cache_path()
    try:
        raw = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return {}
    if raw.get("version") != CACHE_VERSION or not isinstance(raw.get("files"), dict):
        return {}
    return raw["files"]


def _save_disk_cache(files: dict[str, dict]) -> None:
    path = _cache_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps({"version": CACHE_VERSION, "files": files}, separators=(",", ":")))


def memory_cache() -> dict[str, dict]:
    global _file_cache
    if _file_cache is None:
        _file_cache = _load_disk_cache()
    return _file_cache


def flush_cache() -> None:
    global _dirty, _file_cache
    if not _dirty or _file_cache is None:
        return
    cutoff = int(time.time() * 1000) - RETENTION_DAYS * 86400 * 1000 - MTIME_SLACK_MS
    pruned = {k: v for k, v in _file_cache.items() if int(v.get("m", 0)) >= cutoff}
    _save_disk_cache(pruned)
    _file_cache = pruned
    _dirty = False


def get_cached_records(path: Path, provider: str) -> list[tuple] | None:
    try:
        stat = path.stat()
    except OSError:
        return None
    key = str(path)
    entry = memory_cache().get(key)
    if entry is None:
        return None
    if entry.get("p") != provider:
        return None
    if int(entry.get("s", -1)) != stat.st_size or int(entry.get("m", -1)) != int(stat.st_mtime * 1000):
        return None
    rows = entry.get("r")
    if not isinstance(rows, list):
        return None
    return [tuple(row) for row in rows if isinstance(row, list)]


def put_cached_records(path: Path, provider: str, records: list[tuple]) -> None:
    global _dirty
    try:
        stat = path.stat()
    except OSError:
        return
    memory_cache()[str(path)] = {
        "s": stat.st_size,
        "m": int(stat.st_mtime * 1000),
        "p": provider,
        "r": [list(row) for row in records],
    }
    _dirty = True
