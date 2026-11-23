#!/usr/bin/env bash
# Read-only snapshot of the Cloudflare configuration that applies to the
# apex site jeroenoverschie.nl, written to docs/cloudflare-state.json.
# Re-run it and `git diff docs/cloudflare-state.json` to see drift since the
# last snapshot. See docs/cloudflare.md for what each part means and who
# owns it.
#
# Needs the `cf` CLI logged in with read access to the zone. Never writes to
# Cloudflare.
set -euo pipefail

ZONE=bf84d2c33781e394c08b1730aed45601
root="$(cd "$(dirname "$0")/.." && pwd)"
out="$root/docs/cloudflare-state.json"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# All zone settings (GET /zones/:id/settings) plus two that live outside
# that list. A setting whose modified_on is set was changed from its default.
SETTINGS="0rtt advanced_ddos always_online always_use_https
automatic_https_rewrites brotli browser_cache_ttl browser_check cache_level
challenge_ttl ciphers cname_flattening development_mode early_hints ech
edge_cache_ttl email_obfuscation filter_logs_to_cloudflare hotlink_protection
http2 http3 ip_geolocation ipv6 log_to_cloudflare long_lived_grpc max_upload
min_tls_version minify mirage mobile_redirect opportunistic_encryption
opportunistic_onion orange_to_orange origin_error_page_pass_thru polish
pq_keyex prefetch_preload privacy_pass proxy_read_timeout pseudo_ipv4
replace_insecure_js response_buffering rocket_loader security_header
security_level server_side_exclude sort_query_string_for_cache ssl
tls_1_2_only tls_1_3 tls_client_auth true_client_ip_header visitor_ip waf webp
websockets speed_brain rum"

mkdir "$tmp/settings"
for id in $SETTINGS; do
  cf zones settings get "$id" -z "$ZONE" > "$tmp/settings/$id.json"
done

# Zone rulesets this site uses. The response-header one is owned by
# dunnkers/secretary's Terraform (infra/newsletters.tf).
for phase in http_request_cache_settings http_response_headers_transform; do
  cf rulesets entrypoint get "$phase" -z "$ZONE" > "$tmp/ruleset-$phase.json"
done

cf dns records list -z "$ZONE"       > "$tmp/dns.json"
cf dns dnssec get -z "$ZONE"         > "$tmp/dnssec.json"
cf ssl universal settings get -z "$ZONE" > "$tmp/ssl-universal.json"
cf bot-management get -z "$ZONE"     > "$tmp/bot-management.json"
cf page-rules list -z "$ZONE"        > "$tmp/page-rules.json"

node - "$tmp" "$out" <<'EOF'
const fs = require('fs');
const path = require('path');
const [dir, out] = process.argv.slice(2);
const read = (f) => JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8'));
const unwrap = (x) => (x && typeof x === 'object' && 'result' in x ? x.result : x);

const settings = {};
for (const f of fs.readdirSync(path.join(dir, 'settings')).sort()) {
  const s = unwrap(read(path.join('settings', f)));
  settings[s.id] = {value: s.value, modified_on: s.modified_on ?? null};
}

// Only the records that serve the website: subdomains belong to
// dunnkers/secretary (Workers) or the docs host, and mail records (MX, SPF,
// DKIM) are left out so the mail provider isn't named in this repo.
const dns = unwrap(read('dns.json'))
  .filter((r) => ['jeroenoverschie.nl', 'www.jeroenoverschie.nl'].includes(r.name))
  .filter((r) => ['A', 'AAAA', 'CNAME'].includes(r.type))
  .map(({type, name, content, proxied, ttl}) => ({type, name, content, proxied, ttl}))
  .sort((a, b) => (a.name + a.type + a.content).localeCompare(b.name + b.type + b.content));

const ruleset = (f) => {
  const r = unwrap(read(f));
  return {id: r.id, name: r.name, phase: r.phase,
    rules: r.rules.map(({id, description, expression, action, action_parameters, enabled}) =>
      ({id, description, expression, action, action_parameters, enabled}))};
};

const dnssec = unwrap(read('dnssec.json'));
const snapshot = {
  zone: 'jeroenoverschie.nl',
  zone_id: 'bf84d2c33781e394c08b1730aed45601',
  changed_from_default: Object.entries(settings)
    .filter(([, s]) => s.modified_on).map(([id]) => id).sort(),
  settings,
  rulesets: {
    http_request_cache_settings: ruleset('ruleset-http_request_cache_settings.json'),
    http_response_headers_transform: ruleset('ruleset-http_response_headers_transform.json'),
  },
  page_rules: unwrap(read('page-rules.json')),
  dns_apex: dns,
  dnssec: {status: dnssec.status},
  ssl_universal: unwrap(read('ssl-universal.json')),
  bot_management: unwrap(read('bot-management.json')),
};
fs.writeFileSync(out, JSON.stringify(snapshot, null, 2) + '\n');
console.log(`Wrote ${path.relative(process.cwd(), out)}: ${Object.keys(settings).length} settings, ` +
  `${snapshot.changed_from_default.length} changed from default (${snapshot.changed_from_default.join(', ')}).`);
EOF
