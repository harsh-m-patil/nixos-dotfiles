"""Model pricing from models.dev (T3 Code usagePricing-style token math)."""

from __future__ import annotations

import json
import os
import re
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path

MODELS_DEV_URL = "https://models.dev/api.json"
RATES_TTL_MS = 24 * 60 * 60 * 1000
USER_AGENT = "quickshell-usage/1.0 (t3-compatible)"

UNPRICEABLE_MODELS = frozenset(
    {"", "synthetic", "opus", "sonnet", "haiku", "fable", "unknown"},
)

CURSOR_SUFFIXES = (
    "-thinking-high",
    "-thinking",
    "-ultraspeed",
    "-medium-fast",
    "-medium",
    "-high",
    "-low",
    "-fast",
    "-free",
    "-preview",
    "-default",
    "-automation",
)


@dataclass(frozen=True)
class TokenRates:
    input_per_token: float
    output_per_token: float
    cache_read_per_token: float
    cache_write_per_token: float


_rate_table: dict[str, TokenRates] | None = None
_rates_fetched_at_ms: int | None = None
_rates_status: str = "unavailable"
_lookup_cache: dict[str, TokenRates | None] = {}


def _config_dir() -> Path:
    home = os.environ.get("HOME", "~")
    return Path(home).expanduser() / ".config" / "quickshell"


def _rates_cache_path() -> Path:
    return _config_dir() / "usage-models-dev-rates.json"


def _normalize_key(model: str) -> str:
    return model.strip().lower()


def _strip_variant_suffix(key: str) -> str:
    bracket = key.find("[")
    return key[:bracket] if bracket != -1 else key


def _bare_model_name(key: str) -> str:
    slash = key.rfind("/")
    return key[slash + 1 :] if slash != -1 else key


def _million_to_per_token(value: object, fallback: float | None = None) -> float:
    if isinstance(value, (int, float)) and value >= 0:
        return float(value) / 1_000_000
    if fallback is not None:
        return fallback
    return 0.0


def _rates_from_cost(cost: dict) -> TokenRates | None:
    if not isinstance(cost, dict):
        return None
    inp_m = cost.get("input")
    out_m = cost.get("output")
    if not isinstance(inp_m, (int, float)) or not isinstance(out_m, (int, float)):
        return None
    input_pt = _million_to_per_token(inp_m)
    output_pt = _million_to_per_token(out_m)
    cache_read_m = cost.get("cache_read")
    cache_write_m = cost.get("cache_write") or cost.get("cache_creation")
    cache_read_pt = _million_to_per_token(
        cache_read_m,
        fallback=input_pt if input_pt > 0 else None,
    )
    cache_write_pt = _million_to_per_token(
        cache_write_m,
        fallback=input_pt if input_pt > 0 else None,
    )
    return TokenRates(input_pt, output_pt, cache_read_pt, cache_write_pt)


def parse_models_dev_document(document: object) -> dict[str, TokenRates]:
    table: dict[str, TokenRates] = {}
    if not isinstance(document, dict):
        return table

    def iter_models(pdata: object):
        if not isinstance(pdata, dict):
            return
        models = pdata.get("models")
        if isinstance(models, list):
            yield from models
        elif isinstance(models, dict):
            yield from models.values()

    for provider, pdata in document.items():
        for model in iter_models(pdata):
            if not isinstance(model, dict):
                continue
            cost = model.get("cost")
            rates = _rates_from_cost(cost) if isinstance(cost, dict) else None
            if rates is None:
                continue
            model_id = str(model.get("id") or "").strip().lower()
            canonical = str(
                model.get("canonical_model_id") or f"{provider}/{model.get('id', '')}",
            ).strip().lower()
            for key in {model_id, canonical, _bare_model_name(canonical)}:
                if key:
                    table.setdefault(key, rates)

    return table


def _fetch_models_dev() -> dict | None:
    req = urllib.request.Request(MODELS_DEV_URL, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read())
    except (urllib.error.URLError, json.JSONDecodeError, TimeoutError):
        return None


def _load_cache_file() -> tuple[int, dict] | None:
    path = _rates_cache_path()
    try:
        raw = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return None
    fetched = raw.get("fetchedAtMs")
    document = raw.get("document")
    if not isinstance(fetched, int) or not isinstance(document, dict):
        return None
    return fetched, document


def _write_cache_file(fetched_at_ms: int, document: dict) -> None:
    path = _rates_cache_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps({"fetchedAtMs": fetched_at_ms, "document": document}, separators=(",", ":")),
    )


def ensure_model_rates(force: bool = False) -> dict[str, TokenRates]:
    global _rate_table, _rates_fetched_at_ms, _rates_status, _lookup_cache

    now_ms = int(time.time() * 1000)
    max_age = RATES_TTL_MS if not force else 60_000

    if (
        _rate_table is not None
        and _rates_fetched_at_ms is not None
        and now_ms - _rates_fetched_at_ms < max_age
    ):
        return _rate_table

    if _rate_table is None:
        cached = _load_cache_file()
        if cached is not None:
            fetched, document = cached
            parsed = parse_models_dev_document(document)
            if parsed:
                _rate_table = parsed
                _rates_fetched_at_ms = fetched
                _rates_status = "cached"
                _lookup_cache.clear()
                if now_ms - fetched < max_age:
                    return _rate_table

    document = _fetch_models_dev()
    if document is not None:
        parsed = parse_models_dev_document(document)
        if parsed:
            _rate_table = parsed
            _rates_fetched_at_ms = now_ms
            _rates_status = "fresh"
            _lookup_cache.clear()
            _write_cache_file(now_ms, document)
            return _rate_table

    if _rate_table is not None:
        _rates_status = "cached"
        return _rate_table

    _rate_table = {}
    _rates_status = "unavailable"
    return _rate_table


def pricing_meta() -> dict:
    ensure_model_rates()
    fetched = None
    if _rates_fetched_at_ms is not None:
        fetched = datetime_iso(_rates_fetched_at_ms)
    return {
        "status": _rates_status,
        "source": MODELS_DEV_URL,
        "fetchedAt": fetched,
        "knownModels": len(_rate_table or {}),
    }


def datetime_iso(ms: int) -> str:
    from datetime import datetime, timezone

    return datetime.fromtimestamp(ms / 1000, tz=timezone.utc).isoformat()


def lookup_rate(model: str, table: dict[str, TokenRates] | None = None) -> TokenRates | None:
    rates = table if table is not None else ensure_model_rates()
    if model in _lookup_cache:
        return _lookup_cache[model]

    candidates: list[str] = []
    key = _strip_variant_suffix(_normalize_key(model))
    bare = _bare_model_name(key)
    candidates.append(key)
    if bare != key:
        candidates.append(bare)
    stripped = bare
    for suffix in CURSOR_SUFFIXES:
        if stripped.endswith(suffix):
            candidates.append(stripped[: -len(suffix)])
            stripped = stripped[: -len(suffix)]
    # grok-bot-* -> grok-4.7 style heuristics
    if bare.startswith("grok-bot"):
        candidates.append("xai/grok-4.7")
        candidates.append("grok-4.7")
    if bare.startswith("cursor-grok"):
        candidates.append("xai/grok-4.7")
    if re.match(r"^claude-opus-5-5", bare):
        candidates.append("anthropic/claude-opus-5-5")
    if re.match(r"^claude-sonnet-5-5", bare):
        candidates.append("anthropic/claude-sonnet-5-5")
    if re.match(r"^claude-haiku-5-5", bare):
        candidates.append("anthropic/claude-haiku-5-5")
    if re.match(r"^composer-", bare):
        candidates.append("anthropic/claude-sonnet-5-5")

    resolved: TokenRates | None = None
    for candidate in candidates:
        bare_name = _bare_model_name(candidate)
        if bare_name in UNPRICEABLE_MODELS:
            continue
        hit = rates.get(candidate) or rates.get(bare_name)
        if hit is not None:
            resolved = hit
            break

    _lookup_cache[model] = resolved
    return resolved


def price_tokens(
    model: str,
    *,
    uncached_input: int,
    cache_read: int,
    cache_write: int,
    output: int,
    reported_usd: float | None = None,
    table: dict[str, TokenRates] | None = None,
) -> float:
    """Estimate USD; prefer provider-reported cost when model is unpriced."""
    rate = lookup_rate(model, table)
    if rate is None:
        return reported_usd or 0.0

    list_cost = (
        uncached_input * rate.input_per_token
        + cache_read * rate.cache_read_per_token
        + cache_write * rate.cache_write_per_token
        + output * rate.output_per_token
    )
    if reported_usd is not None and reported_usd > 0:
        if list_cost <= 0:
            return reported_usd
        return reported_usd
    return list_cost
