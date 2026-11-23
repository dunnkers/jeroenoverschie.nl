# Cloudflare configuration for jeroenoverschie.nl

The site is a static export hosted on GitHub Pages, served through Cloudflare
(zone `bf84d2c33781e394c08b1730aed45601`, Free plan). This page covers only
what applies to the apex site, `jeroenoverschie.nl` and `www`. The proxied
subdomains `feeds.`, `newsletters.` and `secretary.` are Cloudflare Workers
managed from the **dunnkers/secretary** repo (`infra/`, Terraform). `docs.` is
an unproxied CNAME to a hosted docs service.

`docs/cloudflare-state.json` is a machine-readable snapshot of everything
below, written by `scripts/cloudflare-snapshot.sh`. That script is read-only
and uses the `cf` CLI. Re-run it and `git diff` the file to see what changed
since the last snapshot. Commit the new snapshot together with any deliberate
change.

## Who owns what

| Part | Owner | How to change |
|---|---|---|
| Response-header rules (security headers, **Content-Security-Policy**) | dunnkers/secretary Terraform: `infra/newsletters.tf`, `cloudflare_ruleset.zone_response_headers` | PR in secretary, then `./run.sh plan` / `./run.sh apply` there. **Never edit these in the dashboard or with `cf`**: the next apply reverts it. |
| Everything else on this page | Dashboard / `cf` CLI, by hand | The restore commands below. Update the snapshot afterwards. |

A zone has only one ruleset per phase. Secretary's Terraform imported the
`http_response_headers_transform` ruleset to add a rule for `newsletters.`,
so it now owns every rule in that ruleset, including the apex site's.

## Origin and TLS

- **DNS.** The apex has four proxied A records to GitHub Pages
  (`185.199.108–111.153`). `www` is a proxied CNAME to `dunnkers.github.io`,
  which 301s to the apex.
- **`ssl: full`** (changed from default). Lowered from `strict` on 2026-11-23.
  GitHub Pages' Let's Encrypt certificate expired because its renewal can't
  pass through the proxy, and the site went down with error 526. Don't switch
  back to `strict` while the GitHub certificate is expired. The long-term fix
  (deferred) is moving the static files to Cloudflare Workers static assets
  and then setting `strict` again:
  `cf zones settings edit ssl -z <zone> --body '{"value":"strict"}'`.
- **Universal SSL** is on, with Google as the certificate authority.
  **DNSSEC** is active.
- **`always_use_https: on`** (changed).
- **HSTS** (`security_header`, changed): max-age 15552000 (180 days),
  includeSubDomains on, preload off, nosniff on. `includeSubDomains` also
  covers every subdomain.

## Response headers (owned by secretary's Terraform)

These rules run in order, and the last `set` of a header wins:

1. **"Security headers"**, expression `true`, so it applies to every host in
   the zone:
   - `Permissions-Policy: camera=(), microphone=(), geolocation=()`
   - `Referrer-Policy: strict-origin-when-cross-origin`
   - `X-Content-Type-Options: nosniff`
   - `X-Frame-Options: SAMEORIGIN`
   - `X-XSS-Protection: 0`
2. **"newsletters: Referrer-Policy no-referrer"**, for `newsletters.` only.
3. **"jeroenoverschie.nl: Content-Security-Policy"**, for
   `http.host eq "jeroenoverschie.nl"` only. See below.

### Content-Security-Policy

**Status (2026-11-23):** proposed in dunnkers/secretary, first as
`Content-Security-Policy-Report-Only`. Once it's verified, it changes to
the enforcing `Content-Security-Policy`. Until then the header isn't on the
site.

```
default-src 'none';
script-src 'self' https://static.cloudflareinsights.com 'unsafe-hashes' 'sha256-5iadnZWdOIyuKc+6qo+n3ovJvD1ehK2ddgPlqY04cYk=';
style-src 'self' 'unsafe-inline';
img-src 'self' data:;
font-src 'self';
media-src 'self';
connect-src 'self' https://cloudflareinsights.com;
frame-src https://www.youtube.com https://www.youtube-nocookie.com;
manifest-src 'self';
base-uri 'self';
form-action 'self';
frame-ancestors 'self';
object-src 'none';
upgrade-insecure-requests
```

Why each part is there:

- **`script-src 'self'`.** All scripts are same-origin: the theme bundle,
  Ghost's `/public/cards.min.js`, Cloudflare's `/cdn-cgi/` scripts, and the
  libraries vendored into `assets/vendor/` (see `CLAUDE.md`). No inline
  scripts are allowed, and none are needed.
- **`static.cloudflareinsights.com` / `cloudflareinsights.com`.** Web
  Analytics (see below) injects its beacon script and reports to that host.
- **`'unsafe-hashes' 'sha256-5iad…'`.** Ghost core's bookmark card renders
  `<img onerror="this.style.display = 'none'">`, which the theme can't change.
  The hash allows exactly that handler string and nothing else.
- **`style-src 'unsafe-inline'`.** Ghost emits an inline `<style>` (the accent
  colour) and many `style=""` attributes. Never add a hash or nonce here: when
  one is present, browsers ignore `'unsafe-inline'` and those styles break.
- **`img-src data:`.** Ghost's video card uses a `data:` GIF as its poster.
- **`frame-src` YouTube.** Talk pages embed YouTube videos.

MDN HTTP Observatory treats `'unsafe-inline'` in `style-src` alone as a pass,
so the expected grade is A+ (100/100). It scans only the homepage.

**When the policy has to change** (a PR in secretary, then apply):
- A page fetches from an external API: add it to `connect-src`.
- A page embeds another iframe host: add it to `frame-src`.
- A page needs WebAssembly: add `'wasm-unsafe-eval'` to `script-src`.
- A script library does **not** need a change: vendor it instead (see
  `CLAUDE.md`).
- Ghost changes the bookmark-card handler string: recompute the hash with
  `printf "%s" "<handler>" | openssl dgst -sha256 -binary | base64`.

To test a candidate policy against the live site before applying it, run a
local proxy that fetches pages from the live site and adds the header. Send
the browser's own `User-Agent`, otherwise Cloudflare doesn't inject the
Web Analytics beacon. Then load pages in Chrome and listen for
`securitypolicyviolation` events.

## Caching

Cache rule **"Ghost content"** (`http_request_cache_settings` phase): paths
under `/content/*`, `/assets/*` and `/public/*` are cached, with edge and
browser TTL forced to 1 year (`override_origin`). HTML isn't cached at the
edge (`cf-cache-status: DYNAMIC`). So files under those paths must be
**immutable**: a changed file needs a new URL. Theme assets get this from
`{{asset}}`'s `?v=`, and vendored libraries from their versioned folders.
Zone defaults that also apply: `cache_level: aggressive`,
`browser_cache_ttl: 14400`.

To restore it, take `rulesets.http_request_cache_settings.rules` from the
snapshot without the `id` fields, then:
`cf rulesets entrypoint update http_request_cache_settings -z <zone> --rules '<json array>'`.

## Speed, analytics and scripts Cloudflare adds to pages

- **Web Analytics (RUM): on.** Cloudflare injects
  `<script type="module" src="https://static.cloudflareinsights.com/beacon.min.js/…">`
  into HTML sent to browsers (not to curl). The privacy page discloses this.
- **Speed Brain: on** (the default). Adds `Speculation-Rules: /cdn-cgi/speculation`.
- **Crawler Hints: on** (enabled 2026-09-08).
- **`rocket_loader: off`** (changed). Rocket Loader rewrites `<script>`
  tags and would break the CSP and script ordering. Keep it off.
- **`email_obfuscation: on`** (the default). It would inject a same-origin
  `/cdn-cgi/` decoder script on pages that contain an email address.
  `'self'` covers it.
- **`replace_insecure_js: on`** (changed) and `automatic_https_rewrites: on`
  (the default).
- `minify` is all off, and `polish`, `mirage` and `webp` are off. Images are
  optimised at build time instead (`scripts/generate-modern-images.js`).

## Network

- **`ipv6: on`** (changed). Also on, as defaults: `http2`, `http3`, `0rtt`,
  `early_hints`, `ech`, `pq_keyex`, `min_tls_version: 1.2`, `tls_1_3: zrt`.

## Bots and security

- Bot Fight Mode is off. AI-bot and crawler blocking is disabled, and
  Cloudflare doesn't manage `robots.txt`.
- `security_level: medium`, `browser_check: on`, `challenge_ttl: 1800` (defaults).
- The managed WAF and DDoS rulesets are the Free-plan defaults. There are no
  custom firewall rules, no page rules, and no Worker routes on the apex.

## Restoring a setting

Every zone setting in the snapshot can be set back with:

```bash
cf zones settings edit <setting_id> -z bf84d2c33781e394c08b1730aed45601 --body '{"value": <value from docs/cloudflare-state.json>}'
```

The six settings changed from their defaults are listed under
`changed_from_default` in the snapshot (a setting counts as changed when it
has a `modified_on` date):
- `always_use_https`
- `ipv6`
- `replace_insecure_js`
- `rocket_loader`
- `security_header`
- `ssl`

Everything else in `settings` is the Cloudflare default for this zone.
