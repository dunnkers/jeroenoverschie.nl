#!/usr/bin/env bash
# Fetches llms.txt / llms-full.txt from the local Ghost instance.
#
# curl -sf doesn't follow redirects and -f doesn't treat a 3xx as failure,
# so if this route ever redirects instead of returning content, that
# redirect's own body ("Found. Redirecting to /") would silently get saved
# as the file's contents. Retry a while for real content instead of that
# stub - but never fail the build over this: it's a nice-to-have (an
# llms.txt discovery file), not something worth blocking every deploy for
# if Ghost's instance is slow to serve it on a given run.
#
# The persistent (not transient) 302 seen in CI on every one of 15 attempts
# turned out not to be a timing issue at all: it was ghost:6.45.0, which was
# pinned in the workflows and doesn't serve /llms.txt (always redirects to
# /), confirmed by booting that exact image against the real content DB and
# getting 302 on every request for 40s straight, while ghost:6.53.0 serves
# it correctly from the first request. The workflows are now pinned to
# 6.53.0; this retry loop stays as a safety margin for genuine slow-boot
# cases, not as the primary fix.
url="$1"
out="$2"

for attempt in $(seq 1 10); do
  if curl -sf "$url" -o "$out" 2>/dev/null && ! grep -q "Redirecting to" "$out"; then
    echo "  ${url}: fetched OK (attempt ${attempt}/10)"
    exit 0
  fi
  sleep 2
done

echo "  ${url}: still not returning real content after 10 attempts - leaving it out of this deploy, not failing the build" >&2
rm -f "$out"
exit 0
