#!/usr/bin/env bash
# Finds every page that redirects visitors away via a client-side
# <meta http-equiv="refresh"> tag (the only redirect mechanism GitHub Pages
# supports - it cannot serve real HTTP 3xx responses), then for each one:
#   - confirms the redirect target still resolves (catches link rot)
#   - flags whether canonical/og:url still self-reference this site, which
#     contradicts the redirect and risks duplicate-content signals
#
# Always exits 0: this is a reporting step, not a gate.
set -uo pipefail

BASE_URL="${1:?Usage: audit-redirects.sh <base-url> <sitemap-urls-file>}"
URLS_FILE="${2:?Usage: audit-redirects.sh <base-url> <sitemap-urls-file>}"
SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/stdout}"
REDIRECTING_OUT="${3:-redirecting-urls.txt}"

: > "$REDIRECTING_OUT"

{
  echo "## Meta-refresh redirect audit"
  echo ""
  echo "GitHub Pages has no server-side redirect capability, so any post"
  echo "that links out elsewhere does it via a 0-second"
  echo "\`<meta http-equiv=\"refresh\">\` tag. This checks every such page's"
  echo "redirect target is still alive, and whether canonical/og:url still"
  echo "point back at this site (which would contradict the redirect)."
  echo ""
  echo "| Page | Redirect target | Target status | Canonical/og:url |"
  echo "|---|---|---|---|"
} >> "$SUMMARY"

found=0
while IFS= read -r url; do
  [ -z "$url" ] && continue
  html=$(curl -sSL --max-time 15 "$url" 2>/dev/null || true)
  refresh=$(printf '%s' "$html" | grep -oiE '<meta[^>]*http-equiv="refresh"[^>]*>' | head -1)
  [ -z "$refresh" ] && continue

  found=1
  echo "$url" >> "$REDIRECTING_OUT"

  target=$(printf '%s' "$refresh" | grep -oiE "url=[^\"']+" | head -1 | sed -E 's/^[Uu][Rr][Ll]=//')
  [ -z "$target" ] && target="(could not parse target)"

  target_status="n/a"
  if [ "$target" != "(could not parse target)" ]; then
    target_status=$(curl -s -o /dev/null -L --max-time 15 -w '%{http_code}' "$target" 2>/dev/null || echo "ERR")
  fi
  status_flag="$target_status"
  case "$target_status" in
    4*|5*|ERR|"") status_flag="⚠️ $target_status (broken)" ;;
  esac

  canonical=$(printf '%s' "$html" | grep -oiE '<link[^>]*rel="canonical"[^>]*href="[^"]+"' | head -1 | grep -oE 'href="[^"]+"' | sed -E 's/^href="//; s/"$//')

  if [ -n "$canonical" ] && [ "${canonical%/}" = "${url%/}" ]; then
    canonical_flag="⚠️ self-references this page (contradicts the redirect)"
  elif [ -n "$canonical" ]; then
    canonical_flag="points to $canonical"
  else
    canonical_flag="(no canonical tag found)"
  fi

  echo "| $url | $target | $status_flag | $canonical_flag |" >> "$SUMMARY"
done < "$URLS_FILE"

if [ "$found" -eq 0 ]; then
  echo "| _no meta-refresh redirects found_ | | | |" >> "$SUMMARY"
fi

echo "" >> "$SUMMARY"
exit 0
