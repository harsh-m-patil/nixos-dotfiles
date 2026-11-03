#!/usr/bin/env bash
# Refresh version and fetchurl hash from the stable Grok Bot .deb endpoint.
set -euo pipefail

readonly DEFAULT_URL="https://api2.cursor.sh/updates/download/stable/linux-x64/grok-bot-fb0a830618be0c54"
readonly URL="${1:-$DEFAULT_URL}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nix_file="${script_dir}/default.nix"

if [[ ! -f "$nix_file" ]]; then
  echo "error: missing ${nix_file}" >&2
  exit 1
fi

redirect="$(
  curl -fsSIL "$URL" | tr -d '\r' | awk -F': ' '/^location:/ { print $2; exit }'
)"
if [[ -z "$redirect" ]]; then
  echo "error: no redirect from ${URL}" >&2
  exit 1
fi

deb_name="$(basename "$redirect")"
if [[ ! "$deb_name" =~ ^grok-bot_([0-9.]+)_amd64\.deb$ ]]; then
  echo "error: unexpected deb name: ${deb_name}" >&2
  exit 1
fi
version="${BASH_REMATCH[1]}"

echo "Prefetching ${URL} ..."
hash_b32="$(nix-prefetch-url "$URL")"
hash_sri="$(nix hash to-sri --type sha256 "$hash_b32")"

tmp="$(mktemp)"
cp "$nix_file" "$tmp"
sed -i "s|version = \"[^\"]*\";|version = \"${version}\";|" "$tmp"
sed -i "s|url = \"[^\"]*\";|url = \"${URL}\";|" "$tmp"
sed -i "s|hash = \"sha256-[^\"]*\";|hash = \"${hash_sri}\";|" "$tmp"
mv "$tmp" "$nix_file"

echo "Updated ${nix_file}"
echo "  version: ${version}"
echo "  url:     ${URL}"
echo "  hash:    ${hash_sri}"
echo "  deb:     ${deb_name}"
