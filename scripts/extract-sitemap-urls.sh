#!/usr/bin/env bash
# Resolves Ghost's /sitemap.xml (a sitemap index pointing at sub-sitemaps for
# posts/pages/tags/authors) one level deep and prints every page URL found,
# one per line, deduplicated.
set -euo pipefail

BASE_URL="${1:?Usage: extract-sitemap-urls.sh <base-url>}"

index=$(curl -sSL --max-time 20 "${BASE_URL%/}/sitemap.xml")
locs=$(echo "$index" | grep -oE '<loc>[^<]+</loc>' | sed -E 's#</?loc>##g')

if [ -z "$locs" ]; then
  echo "::warning::No <loc> entries found in ${BASE_URL%/}/sitemap.xml" >&2
  exit 0
fi

for loc in $locs; do
  if [[ "$loc" == *.xml ]]; then
    # It's a sub-sitemap (e.g. sitemap-posts.xml) - fetch and extract its pages.
    curl -sSL --max-time 20 "$loc" | grep -oE '<loc>[^<]+</loc>' | sed -E 's#</?loc>##g'
  else
    # sitemap.xml was already a flat list of page URLs.
    echo "$loc"
  fi
done | sort -u
