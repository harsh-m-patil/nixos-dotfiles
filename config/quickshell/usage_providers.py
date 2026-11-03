"""Local agent usage scanners (same history sources as T3 Code Usage)."""

from __future__ import annotations

import json
import os
import sqlite3
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

from usage_pricing import ensure_model_rates, price_tokens
from usage_scan_cache import flush_cache, get_cached_records, put_cached_records

PROVIDER_LABELS: dict[str, str] = {
    "claude": "Claude Code",
    "codex": "Codex",
    "grok": "Grok Build",
    "cursor": "Cursor",
    "opencode": "OpenCode",
    "antigravity": "Antigravity",
    "pi": "Pi",
    "muse": "Muse Code",
}

LOCAL_PROVIDERS = (
    "claude",
    "codex",
    "grok",
    "opencode",
    "antigravity",
    "pi",
    "muse",
)

DEFAULT_SOURCE_DIRS: dict[str, list[str]] = {
    "claude": ["~/.claude/projects"],
    "codex": ["~/.codex/sessions"],
    "grok": ["~/.grok/sessions"],
    "pi": ["~/.pi/agent/sessions", "~/.pi/sessions"],
    "muse": ["~/.muse/sessions"],
    "antigravity": ["~/.antigravity/conversations", "~/.config/antigravity"],
}


def expand(path: str) -> Path:
    return Path(os.path.expanduser(path)).resolve()


def t3_home() -> Path:
    env = os.environ.get("T3CODE_HOME") or os.environ.get("T3_HOME")
    if env:
        return expand(env)
    return expand("~/.t3")


def t3_scan_sources() -> dict[str, list[Path]]:
    out: dict[str, list[Path]] = {k: [] for k in PROVIDER_LABELS}
    cache_names = (
        "usage-scan-cache-v9.json",
        "usage-scan-cache-v8.json",
        "usage-scan-cache.json",
    )
    for name in cache_names:
        cache = t3_home() / "userdata" / name
        try:
            data = json.loads(cache.read_text())
        except (OSError, json.JSONDecodeError):
            continue
        sources = data.get("sources")
        if not isinstance(sources, dict):
            continue
        for key, meta in sources.items():
            provider = key.split("\x00", 1)[0]
            if provider not in out or not isinstance(meta, dict):
                continue
            directory = meta.get("dir")
            if isinstance(directory, str) and directory:
                p = expand(directory)
                if p not in out[provider]:
                    out[provider].append(p)
    return out


def discover_dirs(provider: str) -> list[Path]:
    dirs: list[Path] = []
    for raw in DEFAULT_SOURCE_DIRS.get(provider, []):
        p = expand(raw)
        if p.is_dir():
            dirs.append(p)
    for p in t3_scan_sources().get(provider, []):
        if p.is_dir() and p not in dirs:
            dirs.append(p)
    env_map = {
        "claude": "CLAUDE_CONFIG_DIR",
        "codex": "CODEX_HOME",
        "grok": "GROK_HOME",
        "pi": "PI_CODING_AGENT_SESSION_DIR",
    }
    env = env_map.get(provider)
    if env and os.environ.get(env):
        p = expand(os.environ[env])
        if p.is_dir() and p not in dirs:
            dirs.append(p)
    if provider == "opencode":
        for raw in (
            os.environ.get("OPENCODE_DATA_DIR"),
            "~/.local/share/opencode",
            "~/.opencode",
        ):
            if not raw:
                continue
            p = expand(raw)
            if p.is_dir() and p not in dirs:
                dirs.append(p)
    return dirs


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
    provider: str = "merged"
    tz_name: str = "UTC"
    cost_usd: float = 0.0
    input_tokens: int = 0
    output_tokens: int = 0
    cache_read_tokens: int = 0
    cache_creation_tokens: int = 0
    events: int = 0
    sessions: set[str] = field(default_factory=set)
    daily: dict[str, DayBucket] = field(default_factory=dict)
    models: dict[str, dict[str, float | int | str]] = field(default_factory=dict)

    def absorb(self, other: UsageRollup) -> None:
        self.cost_usd += other.cost_usd
        self.input_tokens += other.input_tokens
        self.output_tokens += other.output_tokens
        self.cache_read_tokens += other.cache_read_tokens
        self.cache_creation_tokens += other.cache_creation_tokens
        self.events += other.events
        self.sessions |= other.sessions
        for day, bucket in other.daily.items():
            dest = self.daily.setdefault(day, DayBucket())
            dest.add(
                bucket.input_tokens,
                bucket.output_tokens,
                bucket.cache_read_tokens,
                bucket.cost_usd,
            )
        for model, stats in other.models.items():
            key = model if other.provider == "cursor" else f"{other.provider}:{model}"
            row = self.models.setdefault(
                key,
                {"costUsd": 0.0, "totalTokens": 0, "events": 0, "provider": other.provider},
            )
            row["costUsd"] = float(row["costUsd"]) + float(stats["costUsd"])
            row["totalTokens"] = int(row["totalTokens"]) + int(stats["totalTokens"])
            row["events"] = int(row["events"]) + int(stats["events"])

    def add_record(
        self,
        *,
        day: str | None,
        model: str,
        inp: int,
        out: int,
        cache_read: int,
        cache_write: int,
        cost: float,
        session: str | None = None,
    ) -> None:
        self.cost_usd += cost
        self.input_tokens += inp
        self.output_tokens += out
        self.cache_read_tokens += cache_read
        self.cache_creation_tokens += cache_write
        self.events += 1
        if session:
            self.sessions.add(session)
        if day:
            self.daily.setdefault(day, DayBucket()).add(inp, out, cache_read, cost)
        row = self.models.setdefault(
            model, {"costUsd": 0.0, "totalTokens": 0, "events": 0, "provider": self.provider},
        )
        row["costUsd"] = float(row["costUsd"]) + cost
        row["totalTokens"] = int(row["totalTokens"]) + inp + out + cache_read + cache_write
        row["events"] = int(row["events"]) + 1

    def total_tokens(self) -> int:
        return (
            self.input_tokens
            + self.output_tokens
            + self.cache_read_tokens
            + self.cache_creation_tokens
        )

    def to_provider_dict(self) -> dict:
        return {
            "id": self.provider,
            "label": PROVIDER_LABELS.get(self.provider, self.provider),
            "costUsd": round(self.cost_usd, 4),
            "totalTokens": self.total_tokens(),
            "sessions": len(self.sessions),
            "events": self.events,
        }

    def to_cycle_dict(self, start_ms: int, end_ms: int, enumerate_days) -> dict:
        total = self.total_tokens()
        models = sorted(
            (
                {
                    "model": name.split(":", 1)[-1],
                    "provider": str(v.get("provider", self.provider)),
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
            "cacheCreationTokens": self.cache_creation_tokens,
            "events": self.events,
            "sessions": len(self.sessions),
            "models": models[:12],
            "daily": [
                {"day": day, **self.daily.get(day, DayBucket()).to_dict()}
                for day in enumerate_days(start_ms, end_ms, self.tz_name)
            ],
        }


def parse_jsonl_record(provider: str, obj: dict) -> tuple[int, str, int, int, int, int, float] | None:
    model = ""
    ts_ms = 0
    cost = 0.0

    if provider == "opencode":
        if obj.get("role") not in (None, "assistant"):
            return None
        usage = obj.get("tokens")
        if not isinstance(usage, dict):
            return None
        cache = usage.get("cache") if isinstance(usage.get("cache"), dict) else {}
        inp = int(usage.get("input") or 0)
        out = int(usage.get("output") or 0) + int(usage.get("reasoning") or 0)
        cache_read = int(cache.get("read") or 0)
        cache_write = int(cache.get("write") or 0)
        if inp + out + cache_read + cache_write <= 0:
            return None
        model_ref = obj.get("model")
        if isinstance(model_ref, dict):
            model = str(model_ref.get("id") or model_ref.get("modelID") or "")
        model = model or str(obj.get("modelID") or "unknown")
        t = obj.get("time")
        if isinstance(t, dict) and isinstance(t.get("created"), (int, float)):
            ts_ms = int(t["created"])
        c = obj.get("cost")
        if isinstance(c, (int, float)) and c > 0:
            cost = float(c) / 100.0 if c > 20 else float(c)
        return ts_ms, model, inp, out, cache_read, cache_write, cost

    msg = obj.get("message") if isinstance(obj.get("message"), dict) else obj
    usage = None
    if isinstance(msg, dict):
        usage = msg.get("usage") if isinstance(msg.get("usage"), dict) else None
        model = str(msg.get("model") or obj.get("model") or "unknown")
    if usage is None and isinstance(obj.get("usage"), dict):
        usage = obj["usage"]
    if usage is None:
        return None
    inp = int(usage.get("input_tokens") or usage.get("prompt_tokens") or usage.get("input") or 0)
    out = int(usage.get("output_tokens") or usage.get("completion_tokens") or usage.get("output") or 0)
    cache = usage.get("cache") if isinstance(usage.get("cache"), dict) else {}
    cache_read = int(usage.get("cache_read_input_tokens") or cache.get("read") or 0)
    cache_write = int(usage.get("cache_creation_input_tokens") or cache.get("write") or 0)
    if inp + out + cache_read + cache_write <= 0:
        return None
    for key in ("timestamp", "created_at", "created", "timestamp_ms"):
        val = obj.get(key) if key in obj else msg.get(key) if isinstance(msg, dict) else None
        if isinstance(val, (int, float)) and val > 0:
            ts_ms = int(val if val > 1e12 else val * 1000)
            break
        if isinstance(val, str):
            try:
                ts_ms = int(datetime.fromisoformat(val.replace("Z", "+00:00")).timestamp() * 1000)
                break
            except ValueError:
                pass
    return ts_ms, model or "unknown", inp, out, cache_read, cache_write, cost


def resolve_record_cost(
    model: str,
    inp: int,
    out: int,
    cache_read: int,
    cache_write: int,
    reported: float,
    rate_table: dict | None,
) -> float:
    if reported > 0:
        return reported
    return price_tokens(
        model,
        uncached_input=inp,
        cache_read=cache_read,
        cache_write=cache_write,
        output=out,
        table=rate_table,
    )


def parse_jsonl_file(path: Path, provider: str) -> list[tuple]:
    cached = get_cached_records(path, provider)
    if cached is not None:
        return cached

    records: list[tuple] = []
    try:
        with path.open(errors="ignore") as handle:
            for line in handle:
                if not line.strip():
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if not isinstance(obj, dict):
                    continue
                parsed = parse_jsonl_record(provider, obj)
                if not parsed:
                    continue
                ts_ms, model, inp, out, cache_read, cache_write, cost = parsed
                session = str(obj.get("session_id") or obj.get("sessionId") or obj.get("sessionID") or "")
                records.append((ts_ms, model, inp, out, cache_read, cache_write, cost, session))
    except OSError:
        return []

    put_cached_records(path, provider, records)
    return records


def scan_jsonl_tree(
    provider: str,
    root: Path,
    tz_name: str,
    start_ms: int,
    end_ms: int,
    rate_table: dict | None,
) -> UsageRollup:
    rollup = UsageRollup(provider=provider, tz_name=tz_name)
    tz = ZoneInfo(tz_name)
    seen_dedupe: set[str] = set()
    for path in root.rglob("*.jsonl"):
        try:
            if path.stat().st_size > 80_000_000:
                continue
        except OSError:
            continue
        for row in parse_jsonl_file(path, provider):
            ts_ms, model, inp, out, cache_read, cache_write, cost, session = row
            if ts_ms and (ts_ms < start_ms or ts_ms > end_ms):
                continue
            dedupe = f"{provider}:{ts_ms}:{model}:{inp}:{out}:{cache_read}:{cache_write}"
            if dedupe in seen_dedupe:
                continue
            seen_dedupe.add(dedupe)
            cost_usd = resolve_record_cost(
                model, inp, out, cache_read, cache_write, cost, rate_table,
            )
            day = datetime.fromtimestamp((ts_ms or start_ms) / 1000, tz=tz).strftime("%Y-%m-%d")
            rollup.add_record(
                day=day,
                model=model,
                inp=inp,
                out=out,
                cache_read=cache_read,
                cache_write=cache_write,
                cost=cost_usd,
                session=session or None,
            )
    return rollup


def scan_opencode(start_ms: int, end_ms: int, tz_name: str, rate_table: dict | None) -> UsageRollup:
    rollup = UsageRollup(provider="opencode", tz_name=tz_name)
    tz = ZoneInfo(tz_name)
    for root in discover_dirs("opencode"):
        for db in (root / "opencode.db", root / "storage" / "opencode.db"):
            if not db.is_file():
                continue
            try:
                conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
            except sqlite3.Error:
                continue
            for table in ("message", "session_message"):
                try:
                    rows = conn.execute(f"SELECT data FROM {table}").fetchall()
                except sqlite3.Error:
                    continue
                for (raw,) in rows:
                    if not isinstance(raw, str):
                        continue
                    try:
                        obj = json.loads(raw)
                    except json.JSONDecodeError:
                        continue
                    parsed = parse_jsonl_record("opencode", obj)
                    if not parsed:
                        continue
                    ts_ms, model, inp, out, cache_read, cache_write, cost = parsed
                    if ts_ms and (ts_ms < start_ms or ts_ms > end_ms):
                        continue
                    cost_usd = resolve_record_cost(
                        model, inp, out, cache_read, cache_write, cost, rate_table,
                    )
                    day = datetime.fromtimestamp((ts_ms or start_ms) / 1000, tz=tz).strftime("%Y-%m-%d")
                    rollup.add_record(
                        day=day,
                        model=model,
                        inp=inp,
                        out=out,
                        cache_read=cache_read,
                        cache_write=cache_write,
                        cost=cost_usd,
                        session=str(obj.get("sessionID") or "") or None,
                    )
            conn.close()
    return rollup


def scan_provider(
    provider: str,
    start_ms: int,
    end_ms: int,
    tz_name: str,
    rate_table: dict | None,
) -> UsageRollup:
    if provider == "opencode":
        return scan_opencode(start_ms, end_ms, tz_name, rate_table)
    merged = UsageRollup(provider=provider, tz_name=tz_name)
    for directory in discover_dirs(provider):
        merged.absorb(
            scan_jsonl_tree(provider, directory, tz_name, start_ms, end_ms, rate_table),
        )
    return merged


def scan_all_local(
    start_ms: int,
    end_ms: int,
    tz_name: str,
) -> tuple[list[dict], list[UsageRollup]]:
    rate_table = ensure_model_rates()
    parts: list[UsageRollup] = []
    for provider in LOCAL_PROVIDERS:
        part = scan_provider(provider, start_ms, end_ms, tz_name, rate_table)
        if part.events > 0 or part.total_tokens() > 0 or part.cost_usd > 0:
            parts.append(part)
    flush_cache()
    providers = sorted(
        [p.to_provider_dict() for p in parts],
        key=lambda row: (-row["totalTokens"], -row["costUsd"]),
    )
    return providers, parts


def merge_parts(parts: list[UsageRollup]) -> UsageRollup:
    merged = UsageRollup(provider="merged")
    for part in parts:
        merged.absorb(part)
    return merged
