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
# cached for a year, so vendored files are immutable: never edit or
# replace one, vendor a new version instead. Adding *new* files to an
# existing version folder is fine (e.g. another theme of the same
# release); the script refuses to overwrite anything already there.
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

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

meta="$(cd "$tmp" && npm pack "$spec" --json --silent)"
tarball="$(node -e 'const m=JSON.parse(process.argv[1])[0]; process.stdout.write(m.filename)' "$meta")"
mkdir "$tmp/pkg"
tar -xzf "$tmp/$tarball" -C "$tmp/pkg" --strip-components=1

# Check everything before copying anything, so a failed run changes nothing.
for path in "$@"; do
  src="$tmp/pkg/$path"
  if [ ! -e "$src" ]; then
    echo "Not in $spec: $path" >&2
    exit 1
  fi
  rel="${path#dist/}"
  while IFS= read -r f; do
    if [ -e "$dest/$rel${f#"$src"}" ]; then
      echo "Already vendored, refusing to overwrite: ${dest#$root/}/$rel${f#"$src"}" >&2
      exit 1
    fi
  done < <(find "$src" -type f)
done

mkdir -p "$dest"
for path in "$@"; do
  rel="${path#dist/}"
  mkdir -p "$dest/$(dirname "$rel")"
  cp -R "$tmp/pkg/$path" "$dest/$rel"
done

# source.json records where the files came from (metadata only; no page
# references it, so updating it in place is the one allowed exception to
# immutability). A later run for the same
# version adds its paths to the list (the tarball integrity must match).
node -e '
  const fs = require("fs");
  const [m] = JSON.parse(process.argv[1]);
  const file = process.argv[2];
  const prev = fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, "utf8")) : null;
  if (prev && prev.integrity !== m.integrity) {
    console.error(`${file}: integrity differs from the npm tarball; not updating it.`);
    process.exit(1);
  }
  const today = new Date().toISOString().slice(0, 10);
  const out = {package: m.name, version: m.version, integrity: m.integrity,
    tarball: process.argv[3],
    files: [...new Set([...(prev ? prev.files : []), ...process.argv.slice(4)])],
    vendored: prev ? prev.vendored : today};
  if (prev) out.updated = today;
  fs.writeFileSync(file, JSON.stringify(out, null, 2) + "\n");
' "$meta" "$dest/source.json" "$(npm view "$spec" dist.tarball)" "$@"

echo "Vendored $spec into ${dest#$root/}:"
(cd "$dest" && find . -type f | sort | sed 's|^\./|  |')
