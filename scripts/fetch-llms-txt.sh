#!/usr/bin/env bash
# Fetches llms.txt / llms-full.txt from the local Ghost instance.
#
# The "Wait for Ghost to be ready" CI step only confirms the root path
# responds - it doesn't guarantee every route (like llms.txt) is registered
# yet. Hitting llms.txt too early gets a 302 to "/"; curl -sf doesn't follow
# redirects and -f doesn't treat a 3xx as failure, so that redirect's body
# ("Found. Redirecting to /") silently got saved as the file's contents.
# Retry until we get real content instead of that stub.
set -euo pipefail

url="$1"
out="$2"

for attempt in 1 2 3 4 5; do
  if curl -sf "$url" -o "$out" && ! grep -q "Redirecting to" "$out"; then
    exit 0
  fi
  echo "  ${url}: got a redirect stub or failed (attempt ${attempt}/5), retrying..."
  sleep 2
done

echo "  ${url}: still not returning real content after 5 attempts" >&2
exit 1
