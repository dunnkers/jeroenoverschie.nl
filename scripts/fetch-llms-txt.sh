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
# 5 attempts, not 15: in CI this has so far failed 15/15 times on every
# observed run (a cold, resource-constrained Ghost container apparently
# can't render llms.txt - which enumerates every post - fast enough), so
# the extra attempts were just adding ~20s of pure waste per file for a
# retry that never once succeeded. 5 still gives a real chance on a run
# where Ghost happens to be ready sooner, without paying the full 30s tax
# on every deploy when it isn't.
url="$1"
out="$2"

for attempt in $(seq 1 5); do
  if curl -sf "$url" -o "$out" 2>/dev/null && ! grep -q "Redirecting to" "$out"; then
    echo "  ${url}: fetched OK (attempt ${attempt}/5)"
    exit 0
  fi
  sleep 2
done

echo "  ${url}: still not returning real content after 5 attempts - leaving it out of this deploy, not failing the build" >&2
rm -f "$out"
exit 0
