#!/usr/bin/env python3
"""
Make an authenticated request to the Ghost Admin API.

Builds the short-lived JWT Ghost's Admin API requires by hand (HS256, no
third-party deps), so this works even when PyJWT isn't installed.

Reads ADMIN_API_KEY and API_URL from the environment — source the .env file
in the calling shell first (see SKILL.md for why: it keeps secrets out of
tool output).

Usage:
    python3 ghost_admin_request.py GET /ghost/api/admin/site/
    python3 ghost_admin_request.py GET /ghost/api/admin/posts/<id>/
    python3 ghost_admin_request.py PUT /ghost/api/admin/posts/<id>/ '{"posts":[{"title":"New title","updated_at":"2024-01-01T00:00:00.000Z"}]}'
"""
import base64
import hashlib
import hmac
import json
import os
import sys
import time
import urllib.error
import urllib.request
from typing import Optional


def make_token(key_id: str, secret_hex: str) -> str:
    secret = bytes.fromhex(secret_hex)

    def b64url(data: bytes) -> bytes:
        return base64.urlsafe_b64encode(data).rstrip(b"=")

    header = b64url(json.dumps({"alg": "HS256", "typ": "JWT", "kid": key_id}, separators=(",", ":")).encode())
    now = int(time.time())
    # exp must be <= 5 minutes ahead — Ghost rejects longer-lived tokens.
    payload = b64url(json.dumps({"iat": now, "exp": now + 300, "aud": "/admin/"}, separators=(",", ":")).encode())
    signing_input = header + b"." + payload
    sig = b64url(hmac.new(secret, signing_input, hashlib.sha256).digest())
    return (signing_input + b"." + sig).decode()


def admin_request(method: str, path: str, body: Optional[dict] = None):
    admin_key = os.environ["ADMIN_API_KEY"]
    api_url = os.environ["API_URL"]
    key_id, secret_hex = admin_key.split(":")
    token = make_token(key_id, secret_hex)

    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        f"{api_url}{path}",
        data=data,
        method=method,
        headers={"Authorization": f"Ghost {token}", "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status, json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    method, path = sys.argv[1], sys.argv[2]
    body = json.loads(sys.argv[3]) if len(sys.argv) > 3 else None

    status, result = admin_request(method, path, body)
    print(f"status: {status}")
    print(json.dumps(result, indent=2) if isinstance(result, dict) else result)
