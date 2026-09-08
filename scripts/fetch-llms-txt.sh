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
# A persistent (not transient) 302 on every attempt usually means the
# pinned Ghost image itself doesn't serve /llms.txt, not that it's slow to
# boot - check the image version in the workflows first. This loop is a
# safety margin for genuine slow-boot cases, not a fix for that.
url="$1"
out="$2"

for attempt in $(seq 1 15); do
  if curl -sf "$url" -o "$out" 2>/dev/null && ! grep -q "Redirecting to" "$out"; then
    echo "  ${url}: fetched OK (attempt ${attempt}/15)"
    exit 0
  fi
  sleep 2
done

echo "  ${url}: still not returning real content after 15 attempts - leaving it out of this deploy, not failing the build" >&2
rm -f "$out"
exit 0
