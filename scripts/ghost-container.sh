#!/bin/zsh
# Ensures the local Ghost instance runs under Apple container. Apple container
# has no `--restart` policy, so a LaunchAgent runs this at login and every few
# minutes (see scripts/nl.jeroenoverschie.ghost.plist): it starts the
# `container` services, creates the `ghost` container if missing, and starts
# it if stopped. Safe to run repeatedly.
set -eu
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

GHOST_IMAGE="docker.io/library/ghost:6.73.0"
REPO="/Users/dunnkers/git/dunnkers/jeroenoverschie.nl"
THEME="/Users/dunnkers/git/dunnkers/ghost-dunnkers-theme-edition"

container system status >/dev/null 2>&1 || container system start --enable-kernel-install

state=$(container inspect ghost 2>/dev/null | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d[0]["status"]["state"] if d else "")' 2>/dev/null || true)

if [[ -z "$state" ]]; then
  container run -d --name ghost \
    --user "$(id -u):$(id -g)" \
    -p 2368:2368 \
    -v "$REPO/content:/var/lib/ghost/content" \
    -v "$THEME:/var/lib/ghost/content/themes/dunnkers-theme-edition" \
    -e NODE_ENV=development \
    -e database__client=sqlite3 \
    -e database__connection__filename=/var/lib/ghost/content/data/ghost-local.db \
    -e security__staffDeviceVerification=false \
    "$GHOST_IMAGE"
elif [[ "$state" != "running" ]]; then
  container start ghost
fi
