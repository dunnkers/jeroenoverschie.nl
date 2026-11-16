# Source this file to load Ghost API credentials into the current shell:
#
#   source scripts/ghost-env.sh
#
# The secrets live in the macOS keychain (not in a .env file):
#   service "jeroenoverschie.nl-ADMIN_API_KEY"    -> ADMIN_API_KEY
#   service "jeroenoverschie.nl-CONTENT_API_KEY"  -> CONTENT_API_KEY
#
# To (re)store one, run it interactively so the value never lands in shell
# history or the process list (security prompts for the password):
#
#   security add-generic-password -U -a "$USER" -s jeroenoverschie.nl-ADMIN_API_KEY -w
#
# API_URL is not secret: it's the local Ghost container that gssg crawls.
# Override by exporting API_URL before sourcing.

export API_URL="${API_URL:-http://localhost:2368}"

for _ghost_key in ADMIN_API_KEY CONTENT_API_KEY; do
  _ghost_val="$(security find-generic-password -a "$USER" -s "jeroenoverschie.nl-${_ghost_key}" -w 2>/dev/null)"
  if [ -n "$_ghost_val" ]; then
    export "${_ghost_key}=${_ghost_val}"
  else
    echo "ghost-env.sh: ${_ghost_key} not found in keychain (service jeroenoverschie.nl-${_ghost_key})" >&2
  fi
done
unset _ghost_key _ghost_val
