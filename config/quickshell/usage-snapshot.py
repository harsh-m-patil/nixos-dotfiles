#!/usr/bin/env python3
"""Agent usage snapshot for Quickshell (T3 Code Usage sources + Cursor limits API)."""

from __future__ import annotations

import base64
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

from usage_providers import (
    UsageRollup as ProviderRollup,
    merge_parts,
    scan_all_local,
)
from usage_pricing import pricing_meta

DEFAULT_CURSOR_API = "https://api2.cursor.sh"
DASHBOARD_USAGE_URL = "https://cursor.com/api/dashboard/get-filtered-usage-events"

CURSOR_WINDOWS = (
    {"id": "totalPercentUsed", "label": "Overall"},
    {"id": "autoPercentUsed", "label": "Cursor models"},
    {"id": "apiPercentUsed", "label": "Other models"},
)


def clamp_percent(value: float) -> float:
    return max(0.0, min(100.0, value))


def remaining_percent(used: float) -> int:
    return round(100 - clamp_percent(used))


def format_iso_ms(ms: int | float | None) -> str | None:
    if ms is None or not isinstance(ms, (int, float)) or ms <= 0:
        return None
    return datetime.fromtimestamp(ms / 1000, tz=timezone.utc).isoformat()


def local_day_bounds(day: str, tz_name: str) -> tuple[int, int]:
    tz = ZoneInfo(tz_name)
    start = datetime.strptime(day, "%Y-%m-%d").replace(tzinfo=tz)
    end = start.replace(hour=23, minute=59, second=59, microsecond=999_999)
    return int(start.timestamp() * 1000), int(end.timestamp() * 1000)


def today_day(tz_name: str) -> str:
    return datetime.now(ZoneInfo(tz_name)).strftime("%Y-%m-%d")


def cursor_auth_path() -> Path:
    xdg = os.environ.get("XDG_CONFIG_HOME")
    base = Path(xdg) if xdg else Path.home() / ".config"
    return base / "cursor" / "auth.json"


def read_access_token() -> str | None:
    path = cursor_auth_path()
    try:
        data = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return None
    token = data.get("accessToken")
    return token.strip() if isinstance(token, str) and token.strip() else None


def http_json(
    url: str,
    *,
    method: str = "GET",
    headers: dict[str, str] | None = None,
    body: bytes | None = None,
    timeout: float = 20.0,
) -> object:
    req = urllib.request.Request(url, data=body, headers=headers or {}, method=method)
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read())


def fetch_limits(token: str, endpoint: str) -> dict:
    url = f"{endpoint.rstrip('/')}/aiserver.v1.DashboardService/GetCurrentPeriodUsage"
    body = http_json(
        url,
        method="POST",
        body=b"{}",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "connect-protocol-version": "1",
            "x-cursor-client-type": "cli",
        },
    )
    if not isinstance(body, dict):
        raise ValueError("unexpected limits response")
    plan = body.get("planUsage") if isinstance(body.get("planUsage"), dict) else {}
    windows = []
    for spec in CURSOR_WINDOWS:
        used = plan.get(spec["id"])
        if not isinstance(used, (int, float)) or not (used == used):
            continue
        used_f = float(used)
        entry = {
            "id": spec["id"],
            "label": spec["label"],
            "usedPercent": used_f,
            "remainingPercent": remaining_percent(used_f),
        }
        end_ms = body.get("billingCycleEnd")
        end_int = as_epoch_ms(end_ms)
        if end_int is not None:
            entry["resetsAt"] = format_iso_ms(end_int)
        windows.append(entry)
    spend = {}
    for key, out in (
        ("totalSpend", "totalCents"),
        ("includedSpend", "includedCents"),
        ("limit", "limitCents"),
        ("bonusSpend", "bonusCents"),
    ):
        val = plan.get(key)
        if isinstance(val, (int, float)):
            spend[out] = float(val)
    return {
        "windows": windows,
        "billingCycleStartMs": as_epoch_ms(body.get("billingCycleStart")),
        "billingCycleEndMs": as_epoch_ms(body.get("billingCycleEnd")),
        "spend": spend,
    }


def session_cookie(token: str) -> str | None:
    try:
        payload = token.split(".")[1]
        padded = payload + "=" * (-len(payload) % 4)
        claims = json.loads(base64.urlsafe_b64decode(padded))
    except (IndexError, json.JSONDecodeError, ValueError):
        return None
    sub = claims.get("sub")
    if not isinstance(sub, str) or not sub:
        return None
    user_id = sub.split("|")[-1]
    if not user_id:
        return None
    return urllib.parse.quote(f"{user_id}::{token}", safe="")


def day_from_event(event: dict, tz_name: str) -> str | None:
    raw = event.get("timestamp")
    if raw is None:
        return None
    try:
        ms = int(raw)
    except (TypeError, ValueError):
        return None
    if ms <= 0:
        return None
    return datetime.fromtimestamp(ms / 1000, tz=ZoneInfo(tz_name)).strftime("%Y-%m-%d")


def enumerate_days_ms(start_ms: int, end_ms: int, tz_name: str) -> list[str]:
    tz = ZoneInfo(tz_name)
    start = datetime.fromtimestamp(start_ms / 1000, tz=tz).date()
    end = datetime.fromtimestamp(end_ms / 1000, tz=tz).date()
    if end < start:
        return []
    days: list[str] = []
    cursor = start
    while cursor <= end:
        days.append(cursor.strftime("%Y-%m-%d"))
        cursor = cursor.fromordinal(cursor.toordinal() + 1)
    return days


@dataclass
class DayBucket:
    cost_usd: float = 0.0
    input_tokens: int = 0
    output_tokens: int = 0
    cache_read_tokens: int = 0
    events: int = 0

    def add(self, inp: int, out: int, cache: int, cost: float) -> None:
        self.input_tokens += inp
        self.output_tokens += out
        self.cache_read_tokens += cache
        self.cost_usd += cost
        self.events += 1

    @property
    def total_tokens(self) -> int:
        return self.input_tokens + self.output_tokens + self.cache_read_tokens

    def to_dict(self) -> dict:
        return {
            "costUsd": round(self.cost_usd, 4),
            "totalTokens": self.total_tokens,
            "inputTokens": self.input_tokens,
            "outputTokens": self.output_tokens,
            "cacheReadTokens": self.cache_read_tokens,
            "events": self.events,
        }


@dataclass
class UsageRollup:
    cost_usd: float = 0.0
    input_tokens: int = 0
    output_tokens: int = 0
    cache_read_tokens: int = 0
    events: int = 0
    sessions: set[str] = field(default_factory=set)
    daily: dict[str, DayBucket] = field(default_factory=dict)
    models: dict[str, dict[str, float | int]] = field(default_factory=dict)
    tz_name: str = "UTC"

    def add_event(self, event: dict) -> None:
        usage = event.get("tokenUsage")
        if not isinstance(usage, dict):
            return
        inp = int(usage.get("inputTokens") or 0)
        out = int(usage.get("outputTokens") or 0)
        cache = int(usage.get("cacheReadTokens") or 0)
        cents = event.get("chargedCents")
        if not isinstance(cents, (int, float)):
            cents = usage.get("totalCents", 0)
        cost = float(cents or 0) / 100.0
        model = str(event.get("model") or "unknown")
        conv = event.get("conversationId")
        if conv is not None and str(conv) not in ("", "null"):
            self.sessions.add(str(conv))
        day = day_from_event(event, self.tz_name)
        if day:
            self.daily.setdefault(day, DayBucket()).add(inp, out, cache, cost)
        self.cost_usd += cost
        self.input_tokens += inp
        self.output_tokens += out
        self.cache_read_tokens += cache
        self.events += 1
        bucket = self.models.setdefault(
            model, {"costUsd": 0.0, "totalTokens": 0, "events": 0},
        )
        bucket["costUsd"] = float(bucket["costUsd"]) + cost
        bucket["totalTokens"] = int(bucket["totalTokens"]) + inp + out + cache
        bucket["events"] = int(bucket["events"]) + 1

    def daily_series(self, start_ms: int, end_ms: int) -> list[dict]:
        series: list[dict] = []
        for day in enumerate_days_ms(start_ms, end_ms, self.tz_name):
            bucket = self.daily.get(day, DayBucket())
            series.append({"day": day, **bucket.to_dict()})
        return series

    def to_dict(self, start_ms: int | None = None, end_ms: int | None = None) -> dict:
        total = self.input_tokens + self.output_tokens + self.cache_read_tokens
        models = sorted(
            (
                {
                    "model": name,
                    "costUsd": round(float(v["costUsd"]), 4),
                    "totalTokens": int(v["totalTokens"]),
                    "events": int(v["events"]),
                }
                for name, v in self.models.items()
            ),
            key=lambda row: (-row["totalTokens"], -row["costUsd"]),
        )
        return {
            "costUsd": round(self.cost_usd, 4),
            "totalTokens": total,
            "inputTokens": self.input_tokens,
            "outputTokens": self.output_tokens,
            "cacheReadTokens": self.cache_read_tokens,
            "events": self.events,
            "sessions": len(self.sessions),
            "models": models[:8],
            "daily": self.daily_series(start_ms, end_ms)
            if start_ms is not None and end_ms is not None
            else [],
        }


def fetch_usage_events(
    cookie: str,
    start_ms: int,
    end_ms: int,
    tz_name: str = "UTC",
) -> UsageRollup:
    rollup = UsageRollup(tz_name=tz_name)
    page = 1
    page_size = 1000
    total: int | None = None
    max_pages = 50
    while page <= max_pages:
        payload = json.dumps(
            {
                "page": page,
                "pageSize": page_size,
                "startDate": str(start_ms),
                "endDate": str(end_ms),
            },
        ).encode()
        try:
            body = http_json(
                DASHBOARD_USAGE_URL,
                method="POST",
                body=payload,
                headers={
                    "Content-Type": "application/json",
                    "Origin": "https://cursor.com",
                    "Cookie": f"WorkosCursorSessionToken={cookie}",
                },
            )
        except urllib.error.HTTPError as err:
            raise RuntimeError(f"usage events HTTP {err.code}") from err
        if not isinstance(body, dict):
            break
        if total is None:
            count = body.get("totalUsageEventsCount")
            total = int(count) if isinstance(count, (int, float)) else None
        events = body.get("usageEventsDisplay")
        if not isinstance(events, list) or not events:
            break
        for raw in events:
            if isinstance(raw, dict):
                rollup.add_event(raw)
        if len(events) < page_size:
            break
        if total is not None and rollup.events >= total:
            break
        page += 1
    return rollup


def local_tz_name() -> str:
    link = Path("/etc/localtime")
    if link.is_symlink():
        name = link.resolve().name
        if name and name != "localtime":
            try:
                ZoneInfo(name)
                return name
            except Exception:
                pass
    now = datetime.now().astimezone()
    info = now.tzinfo
    if info is not None and hasattr(info, "key"):
        return str(info.key)
    tz = os.environ.get("TZ")
    if tz:
        try:
            ZoneInfo(tz)
            return tz
        except Exception:
            pass
    return "UTC"


def as_epoch_ms(value: object) -> int | None:
    if isinstance(value, (int, float)) and value > 0:
        return int(value)
    if isinstance(value, str) and value.isdigit():
        return int(value)
    return None


def cursor_rollup_to_provider(cursor: UsageRollup) -> ProviderRollup:
    out = ProviderRollup(provider="cursor", tz_name=cursor.tz_name)
    out.cost_usd = cursor.cost_usd
    out.input_tokens = cursor.input_tokens
    out.output_tokens = cursor.output_tokens
    out.cache_read_tokens = cursor.cache_read_tokens
    out.events = cursor.events
    out.sessions = set(cursor.sessions)
    for day, bucket in cursor.daily.items():
        dest = out.daily.setdefault(day, DayBucket())
        dest.cost_usd += bucket.cost_usd
        dest.input_tokens += bucket.input_tokens
        dest.output_tokens += bucket.output_tokens
        dest.cache_read_tokens += bucket.cache_read_tokens
        dest.events += bucket.events
    for model, stats in cursor.models.items():
        out.models[model] = {
            "costUsd": stats["costUsd"],
            "totalTokens": stats["totalTokens"],
            "events": stats["events"],
            "provider": "cursor",
        }
    return out


def main() -> int:
    tz_name = local_tz_name()
    day = today_day(tz_name)

    out: dict = {
        "ok": False,
        "source": "t3-local",
        "readAt": datetime.now(timezone.utc).isoformat(),
        "timeZone": tz_name,
        "error": None,
        "limits": None,
        "providers": [],
        "today": None,
        "cycle": None,
        "pricing": None,
    }

    token = read_access_token()
    endpoint = (
        os.environ.get("CURSOR_API_ENDPOINT", "").strip()
        or DEFAULT_CURSOR_API
    )

    limits = None
    cycle_start: int | None = None
    cycle_end: int | None = None
    if token:
        try:
            limits = fetch_limits(token, endpoint)
            out["limits"] = limits
            cycle_start = limits.get("billingCycleStartMs")
            cycle_end = limits.get("billingCycleEndMs")
        except Exception as exc:  # noqa: BLE001
            out["error"] = f"Cursor limits: {exc}"
    else:
        out["error"] = "Cursor limits need ~/.config/cursor/auth.json."

    if not isinstance(cycle_start, int) or not isinstance(cycle_end, int) or cycle_end <= cycle_start:
        now = datetime.now(ZoneInfo(tz_name))
        cycle_end = int(now.timestamp() * 1000)
        cycle_start = cycle_end - 30 * 86400 * 1000

    local_providers, local_parts = scan_all_local(cycle_start, cycle_end, tz_name)
    out["pricing"] = pricing_meta()
    parts: list[ProviderRollup] = list(local_parts)

    cookie = session_cookie(token) if token else None
    cursor_cycle: UsageRollup | None = None
    if cookie:
        try:
            cursor_cycle = fetch_usage_events(cookie, cycle_start, cycle_end, tz_name)
            parts.append(cursor_rollup_to_provider(cursor_cycle))
        except Exception as exc:  # noqa: BLE001
            if not out["error"]:
                out["error"] = str(exc)

    merged = merge_parts(parts)
    providers = sorted(
        [p.to_provider_dict() for p in parts if p.events or p.total_tokens() or p.cost_usd],
        key=lambda row: (-row["totalTokens"], -row["costUsd"]),
    )
    out["providers"] = providers

    out["cycle"] = merged.to_cycle_dict(cycle_start, cycle_end, enumerate_days_ms)

    today_bucket = next((d for d in out["cycle"].get("daily", []) if d.get("day") == day), None)
    if today_bucket:
        out["today"] = {"day": day, **today_bucket}
    else:
        out["today"] = {"day": day, "costUsd": 0, "totalTokens": 0, "events": 0, "models": []}

    out["ok"] = bool(providers or (limits and limits.get("windows")))

    print(json.dumps(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
