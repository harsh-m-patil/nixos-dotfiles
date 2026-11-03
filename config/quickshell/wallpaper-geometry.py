#!/usr/bin/env python3
"""Detect image size and whether it is a landscape desktop wallpaper."""

from __future__ import annotations

import struct
import sys
from pathlib import Path

import os

MIN_WIDTH = int(os.environ.get("WALLPAPER_MIN_WIDTH", "1280"))
MIN_RATIO = float(os.environ.get("WALLPAPER_MIN_RATIO", "1.2"))

# Stricter bar for “keep this wallpaper” (stdlib only: headers + file size).
WORTHY_MIN_WIDTH = int(os.environ.get("WALLPAPER_WORTHY_MIN_WIDTH", "1920"))
WORTHY_MIN_RATIO = float(os.environ.get("WALLPAPER_WORTHY_MIN_RATIO", "1.45"))
WORTHY_MAX_RATIO = float(os.environ.get("WALLPAPER_WORTHY_MAX_RATIO", "2.35"))
WORTHY_MIN_BPP = float(os.environ.get("WALLPAPER_WORTHY_MIN_BPP", "0.035"))
WORTHY_MIN_BYTES = int(os.environ.get("WALLPAPER_WORTHY_MIN_BYTES", "250000"))


def _jpeg_size(data: bytes) -> tuple[int, int] | None:
    i = 2
    while i < len(data) - 8:
        if data[i] != 0xFF:
            i += 1
            continue
        marker = data[i + 1]
        if marker in (0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF):
            h, w = struct.unpack(">HH", data[i + 5 : i + 9])
            return w, h
        if i + 3 >= len(data):
            break
        seg_len = struct.unpack(">H", data[i + 2 : i + 4])[0]
        i += 2 + seg_len
    return None


def _png_size(data: bytes) -> tuple[int, int] | None:
    if data[:8] != b"\x89PNG\r\n\x1a\n" or len(data) < 24:
        return None
    w, h = struct.unpack(">II", data[16:24])
    return w, h


def _webp_size(data: bytes) -> tuple[int, int] | None:
    if len(data) < 30 or data[:4] != b"RIFF" or data[8:12] != b"WEBP":
        return None
    tag = data[12:16]
    if tag == b"VP8 " and len(data) >= 30:
        w, h = struct.unpack("<HH", data[26:30])
        return w & 0x3FFF, h & 0x3FFF
    if tag == b"VP8L" and len(data) >= 25:
        bits = struct.unpack("<I", data[21:25])[0]
        w = (bits & 0x3FFF) + 1
        h = ((bits >> 14) & 0x3FFF) + 1
        return w, h
    if tag == b"VP8X" and len(data) >= 30:
        w = 1 + data[24] + (data[25] << 8) + (data[26] << 16)
        h = 1 + data[27] + (data[28] << 8) + (data[29] << 16)
        return w, h
    return None


def image_size(path: Path | str) -> tuple[int, int] | None:
    path = Path(path)
    try:
        data = path.read_bytes()
    except OSError:
        return None
    if data[:2] == b"\xff\xd8":
        return _jpeg_size(data)
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        return _png_size(data)
    if data[:4] == b"RIFF":
        return _webp_size(data)
    return None


def is_desktop_landscape(path: Path | str, min_width: int = MIN_WIDTH, min_ratio: float = MIN_RATIO) -> bool:
    size = image_size(path)
    if not size:
        return False
    w, h = size
    if w < min_width or h < 1:
        return False
    return (w / h) >= min_ratio


def wallpaper_metrics(path: Path | str) -> dict | None:
    path = Path(path)
    size = image_size(path)
    if not size:
        return None
    w, h = size
    try:
        nbytes = path.stat().st_size
    except OSError:
        return None
    ratio = w / h if h else 0.0
    bpp = nbytes / (w * h) if w * h else 0.0
    return {"width": w, "height": h, "ratio": ratio, "bytes": nbytes, "bpp": bpp}


def is_wallpaper_worthy(path: Path | str) -> tuple[bool, str]:
    """Heuristic quality gate without decoding pixels (no Pillow/ffmpeg)."""
    if not is_desktop_landscape(path):
        return False, "not landscape desktop"
    m = wallpaper_metrics(path)
    if not m:
        return False, "unreadable"
    w, h = m["width"], m["height"]
    if w < WORTHY_MIN_WIDTH:
        return False, f"width {w} < {WORTHY_MIN_WIDTH}"
    ratio = m["ratio"]
    if ratio < WORTHY_MIN_RATIO:
        return False, f"aspect {ratio:.2f} < {WORTHY_MIN_RATIO}"
    if ratio > WORTHY_MAX_RATIO:
        return False, f"aspect {ratio:.2f} > {WORTHY_MAX_RATIO}"
    if m["bytes"] < WORTHY_MIN_BYTES:
        return False, f"file {m['bytes']} B < {WORTHY_MIN_BYTES}"
    if m["bpp"] < WORTHY_MIN_BPP:
        return False, f"bpp {m['bpp']:.4f} < {WORTHY_MIN_BPP} (over-compressed?)"
    return True, "ok"


def main() -> int:
    if len(sys.argv) < 3:
        print(
            "usage: wallpaper-geometry.py check|worthy <image> [-v]",
            file=sys.stderr,
        )
        return 2
    cmd, target = sys.argv[1], sys.argv[2]
    verbose = len(sys.argv) > 3 and sys.argv[3] == "-v"
    if cmd == "check":
        ok = is_desktop_landscape(target)
        if verbose:
            s = image_size(target)
            print(s if s else "unknown", "ok" if ok else "reject")
        return 0 if ok else 1
    if cmd == "worthy":
        ok, reason = is_wallpaper_worthy(target)
        if verbose:
            m = wallpaper_metrics(target)
            print(m if m else "unknown", reason)
        return 0 if ok else 1
    print("usage: wallpaper-geometry.py check|worthy <image> [-v]", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
