---
name: ghost-api
description: How to authenticate and call the Ghost CMS Admin API and Content API (reading/writing posts, tags, pages, settings via ghost.org's REST APIs). Use this whenever the user wants to bulk-edit, audit, migrate, or script changes to a Ghost blog/site's content or settings via the API — not the Ghost Admin UI — including tasks like "update all posts tagged X", "fetch post data via the API", "check my Ghost API key works", or anything mentioning ADMIN_API_KEY, CONTENT_API_KEY, or Ghost's `/ghost/api/` endpoints. Also trigger if the user is debugging a 401/403 from Ghost's API, or asks why a JWT/key isn't working with Ghost.
---

# Ghost CMS API (Admin + Content)

Ghost exposes two separate REST APIs with very different auth models. Mixing them up is the most common source of confusion.

| | Content API | Admin API |
|---|---|---|
| Auth | `?key=<CONTENT_API_KEY>` query param | Hand-built short-lived JWT |
| Can write? | No — read only | Yes — full CRUD |
| Typical use | Render public content, list posts/tags | Bulk-edit posts, change settings |

## Getting credentials safely

If credentials live in a `.env` file you've been told not to read directly, don't `Read`/`cat` it. Instead source it in a bash subshell so secrets never appear in tool output or the transcript:

```bash
set -a && source .env && set +a
```

Confirm a var is present without ever printing its value:

```bash
echo "ADMIN_API_KEY set: ${ADMIN_API_KEY:+yes}"
```

## Content API — read-only, simple

Just append the key as a query param. No token to build.

```bash
curl -s "${API_URL}/ghost/api/content/posts/?key=${CONTENT_API_KEY}&filter=tag:talks&fields=title,custom_excerpt&limit=all"
```

Notes:
- `limit=all` works but Ghost 6+ caps the actual result count at 100 — if a query could return more than that, paginate with `page=` instead of relying on `limit=all`.
- Supports `filter` (NQL syntax, e.g. `tag:talks`, `status:published`), `fields`, `include`, `order`.
- Good for read-only checks before you go write something via the Admin API — verify what's currently stored before changing it.

## Admin API — write access, needs a JWT

The Admin API does **not** accept the key as a bearer token or query param. You must build a short-lived JWT yourself:

1. `ADMIN_API_KEY` is formatted `<id>:<secret>` — split on the colon.
2. `<secret>` is **hex-encoded** — decode it with `bytes.fromhex(secret)` before using it as the HMAC key. Using the raw hex string instead of the decoded bytes is the easiest mistake to make here and produces a confusing signature-mismatch failure.
3. JWT header needs `kid` set to the `<id>` half.
4. JWT payload needs `iat` (now), `exp` (at most `iat + 300` — Ghost rejects anything longer-lived than 5 minutes), and `aud` set to `/admin/`.
5. Send it as `Authorization: Ghost <token>` — note the scheme is literally `Ghost`, not `Bearer`.

You don't need PyJWT for this — HS256 is simple enough to build with stdlib `hmac`, `hashlib`, `base64`, `json`. A ready-to-use implementation is bundled at `scripts/ghost_admin_request.py` — use it directly instead of re-deriving the JWT logic each time:

```bash
set -a && source .env && set +a
python3 .claude/skills/ghost-api/scripts/ghost_admin_request.py GET /ghost/api/admin/site/
```

`GET /ghost/api/admin/site/` is the cheapest way to sanity-check that a token/key actually works — it's authenticated, has no side effects, and returns basic site info (title, version, url).

## Updating posts — optimistic concurrency

Ghost requires the current `updated_at` timestamp on every write, as a guard against clobbering concurrent edits (the same idea as an HTTP `If-Match`/ETag check). Skipping this is the second most common failure mode after the JWT secret encoding issue above.

The pattern is always:

1. **GET** the post to read its current `updated_at`.
2. **PUT** to `/ghost/api/admin/posts/{id}/` with only the fields you're changing, plus that `updated_at` — you do not need to send the full post body.

```bash
python3 .claude/skills/ghost-api/scripts/ghost_admin_request.py GET /ghost/api/admin/posts/<id>/
# read "updated_at" from the response, then:
python3 .claude/skills/ghost-api/scripts/ghost_admin_request.py PUT /ghost/api/admin/posts/<id>/ \
  '{"posts":[{"title":"New title","custom_excerpt":"New excerpt","updated_at":"<value from GET>"}]}'
```

If you're updating many posts (e.g. "retitle everything tagged X"), script the GET→PUT pair in a loop rather than doing it one-by-one by hand — this is exactly the kind of repetitive task worth a short Python loop using `ghost_admin_request.py`'s `admin_request()` function directly rather than shelling out per post.

## Quick troubleshooting

- **401/Unauthorized on Admin API**: usually the secret wasn't hex-decoded before HMAC, or the token's `exp` is more than 5 minutes out, or the `Authorization` header says `Bearer` instead of `Ghost`.
- **`updated_at` mismatch / edit conflict on PUT**: you fetched the post too long ago, or something else edited it since — re-GET and retry.
- **Content API returns fewer results than expected**: check whether you hit the 100-item cap from `limit=all`; paginate instead.

## Official docs

This skill covers the gotchas that aren't obvious from the docs. For full endpoint references, parameters, and resource schemas (posts, pages, tags, members, tiers, etc.), fetch these directly:

- Admin API: https://docs.ghost.org/admin-api
- Content API: https://docs.ghost.org/content-api
