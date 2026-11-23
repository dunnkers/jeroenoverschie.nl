#!/bin/zsh
# Ensures the local Ghost instance runs under Apple container. Apple container
# has no `--restart` policy, so a LaunchAgent runs this at login and every few
# minutes (see scripts/nl.jeroenoverschie.ghost.plist): it starts the
# `container` services, creates the `ghost` container if missing, and starts
# it if stopped. A container whose mounts no longer match is recreated.
# Safe to run repeatedly.
set -eu
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

GHOST_IMAGE="docker.io/library/ghost:6.78.0"
REPO="/Users/dunnkers/git/dunnkers/jeroenoverschie.nl"

container system status >/dev/null 2>&1 || container system start --enable-kernel-install

# Prints the container's state, plus "stale" when its mounts differ from the
# single content mount below (e.g. a container created back when the theme
# lived in a separate repo and was mounted over content/themes on its own).
read -r state stale <<<"$(container inspect ghost 2>/dev/null | python3 -c '
import json, sys
d = json.load(sys.stdin)
if not d:
    sys.exit()
mounts = {(m["source"].rstrip("/"), m["destination"].rstrip("/")) for m in d[0]["configuration"].get("mounts", [])}
want = {(sys.argv[1] + "/content", "/var/lib/ghost/content")}
print(d[0]["status"]["state"], "stale" if mounts != want else "ok")
' "$REPO" 2>/dev/null || true)"

if [[ "$stale" == "stale" ]]; then
  # Recreate rather than keep serving outdated mounts. Content and the
  # database live in the bind-mounted content/ folder, so nothing is lost.
  container stop ghost >/dev/null 2>&1 || true
  container delete ghost
  state=""
fi

if [[ -z "$state" ]]; then
  container run -d --name ghost \
    --user "$(id -u):$(id -g)" \
    -p 2368:2368 \
    -v "$REPO/content:/var/lib/ghost/content" \
    -e NODE_ENV=development \
    -e database__client=sqlite3 \
    -e database__connection__filename=/var/lib/ghost/content/data/ghost-local.db \
    -e security__staffDeviceVerification=false \
    "$GHOST_IMAGE"
elif [[ "$state" != "running" ]]; then
  container start ghost
fi
