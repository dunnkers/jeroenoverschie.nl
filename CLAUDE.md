# jeroenoverschie.nl

Personal blog on Ghost CMS, statically exported via `gssg` and hosted on
GitHub Pages (no live backend in production — see `.github/workflows/deploy_website.yaml`).
Theme lives in a separate repo, checked out as a sibling directory at
`../ghost-dunnkers-theme-edition` (do not confuse with the empty,
gitignored `content/themes/dunnkers-theme-edition` placeholder inside
this repo).

## Local Ghost instance

A Ghost Docker container runs locally for content editing and as the
source `gssg` crawls at build time. `content/data/ghost-local.db` is the
live content database, checked into this repo — treat it as real user
data, not a fixture (do not read or write it directly, e.g. via `sqlite3`;
go through the Admin API instead, see below).

## Ghost Admin API

`.env` (gitignored, never read its contents directly — it holds real
secrets) provides:

- `ADMIN_API_KEY` — format `<key_id>:<hex_secret>`, used to sign a JWT
- `API_URL` — the local Ghost instance, e.g. `http://localhost:2368`

To call the Admin API, write and run a throwaway Node script (Node 26 in
this environment has built-in `fetch`/`FormData`/`crypto`, no deps
needed) that:

1. Parses `.env` at runtime into `process.env`-like values — never prints
   or echoes the raw key/secret.
2. Builds an Admin API JWT: split `ADMIN_API_KEY` on `:` into `keyId` /
   `keySecret`; HS256-sign `{iat, exp: iat+300, aud: "/admin/"}` with
   `Buffer.from(keySecret, "hex")`, header `{alg: "HS256", typ: "JWT", kid: keyId}`;
   send as `Authorization: Ghost <token>`.
3. Hits `${API_URL}/ghost/api/admin/...` — e.g. `POST /images/upload/`
   (multipart `FormData` with `file` + `purpose=image`) to upload media,
   or `PUT /posts/:id/` (with the post's current `updated_at` for
   optimistic locking) to update fields like `feature_image`.

Used this way on 2026-09-08 to migrate 4 posts off external Unsplash
feature images onto Ghost's own local media pipeline (so responsive
`srcset`/on-demand resizing applies) — see git history for
`scripts/migrate-feature-images.js`-style usage if a similar migration
comes up again.

## Build pipeline

`npm run build` (in this repo) runs `gssg` against the local Ghost
container, then `scripts/fix-content-images.js` rewrites in-body
`<img>` tags lacking `srcset` to use Ghost's already-generated
`content/images/size/wNNN/...` variants, copying any variant into
`static/` that only exists in the source `content/images/size/` tree
(gssg only downloads sizes it actually saw referenced during its own
crawl, so a width introduced after that crawl needs an explicit copy —
see the `ensureStaticCopy` function).
