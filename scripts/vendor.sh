#!/usr/bin/env bash
# Vendor an npm package's files into the theme, at
# content/themes/dunnkers-theme-edition/assets/vendor/<name>@<version>/,
# for use from a post's code injection, e.g.
#   <script defer src="/assets/vendor/katex@0.19.1/katex.min.js"></script>
#
# Usage: scripts/vendor.sh <name>@<exact-version> <path-in-package>...
#   scripts/vendor.sh katex@0.19.1 dist/katex.min.js dist/fonts
#
# Each path is copied relative to the package root, minus a leading
# "dist/", so relative references inside the files (e.g. a CSS file's
# url(fonts/...)) keep working. Directories are copied recursively.
#
# Why vendor rather than link a CDN: the site's Content-Security-Policy
# allows scripts only from 'self' (see docs/cloudflare.md), and /assets/* is
# cached for a year, so a version folder is immutable:
# never edit it, vendor a new version instead.
set -euo pipefail

if [ $# -lt 2 ]; then
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
fi

spec="$1"; shift
case "$spec" in
  *@*.*) ;;
  *) echo "Give an exact version: <name>@<x.y.z> (got '$spec')." >&2; exit 1 ;;
esac

root="$(cd "$(dirname "$0")/.." && pwd)"
dest="$root/content/themes/dunnkers-theme-edition/assets/vendor/$spec"
if [ -e "$dest" ]; then
  echo "$dest already exists; vendored versions are immutable." >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

meta="$(cd "$tmp" && npm pack "$spec" --json --silent)"
tarball="$(node -e 'const m=JSON.parse(process.argv[1])[0]; process.stdout.write(m.filename)' "$meta")"
mkdir "$tmp/pkg"
tar -xzf "$tmp/$tarball" -C "$tmp/pkg" --strip-components=1

mkdir -p "$dest"
for path in "$@"; do
  src="$tmp/pkg/$path"
  if [ ! -e "$src" ]; then
    echo "Not in $spec: $path" >&2
    rm -rf "$dest"
    exit 1
  fi
  rel="${path#dist/}"
  mkdir -p "$dest/$(dirname "$rel")"
  cp -R "$src" "$dest/$rel"
done

node -e '
  const [m] = JSON.parse(process.argv[1]);
  const out = {package: m.name, version: m.version, integrity: m.integrity,
    tarball: process.argv[2], files: process.argv.slice(3),
    vendored: new Date().toISOString().slice(0, 10)};
  process.stdout.write(JSON.stringify(out, null, 2) + "\n");
' "$meta" "$(npm view "$spec" dist.tarball)" "$@" > "$dest/source.json"

echo "Vendored $spec into ${dest#$root/}:"
(cd "$dest" && find . -type f | sort | sed 's|^\./|  |')
