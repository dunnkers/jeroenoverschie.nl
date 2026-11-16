# Source this file (from the repo root) to load Ghost API credentials into
# the current shell:
#
#   source scripts/ghost-env.sh
#
# The secrets live in the macOS keychain (not in a .env file):
#   service "jeroenoverschie.nl-ADMIN_API_KEY"    -> ADMIN_API_KEY
#   service "jeroenoverschie.nl-CONTENT_API_KEY"  -> CONTENT_API_KEY
#
# If a key can't be loaded this prints why and returns non-zero, so
# `source scripts/ghost-env.sh && <command>` does not run <command>.
#
# To (re)store one, run it interactively so the value never lands in shell
# history or the process list (security prompts for the password):
#
#   security add-generic-password -U -a "$USER" -s jeroenoverschie.nl-ADMIN_API_KEY -w
#
# API_URL is not secret: it defaults to the local Ghost container that gssg
# crawls. An API_URL already exported in your shell takes precedence.

export API_URL="${API_URL:-http://localhost:2368}"

_ghost_env_load() {
  local key val rc=0
  if ! command -v security >/dev/null 2>&1; then
    echo "ghost-env.sh: the macOS 'security' CLI is required to read the keychain" >&2
    return 1
  fi
  for key in ADMIN_API_KEY CONTENT_API_KEY; do
    # `|| val=""`: a missing item must not trip `set -e` in the caller
    val="$(security find-generic-password -a "$USER" -s "jeroenoverschie.nl-${key}" -w 2>/dev/null)" || val=""
    if [ -n "$val" ]; then
      export "${key}=${val}"
    else
      echo "ghost-env.sh: ${key} not found in keychain (service jeroenoverschie.nl-${key})" >&2
      rc=1
    fi
  done
  return "$rc"
}

if _ghost_env_load; then
  unset -f _ghost_env_load
else
  unset -f _ghost_env_load
  return 1 2>/dev/null || exit 1
fi
