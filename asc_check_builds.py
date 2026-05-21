#!/usr/bin/env python3
"""
Quick diagnostic: list all builds and pre-release versions for BarFringer.
"""

import time

import jwt
import requests

KEY_ID = "693WCL562S"
ISSUER_ID = "6c72d64b-298f-4fe8-ae61-551055fa6cde"
KEY_PATH = "/Users/linhan/.private_keys/AuthKey_693WCL562S.p8"
BUNDLE_ID = "com.fringer.app"
BASE_URL = "https://api.appstoreconnect.apple.com"


def generate_token() -> str:
    with open(KEY_PATH, "r") as f:
        private_key = f.read()
    now = int(time.time())
    payload = {
        "iss": ISSUER_ID,
        "iat": now,
        "exp": now + 1200,
        "aud": "appstoreconnect-v1",
    }
    return jwt.encode(payload, private_key, algorithm="ES256", headers={"kid": KEY_ID})


def api_get(token: str, path: str, params: dict | None = None) -> dict:
    url = f"{BASE_URL}{path}"
    headers = {"Authorization": f"Bearer {token}"}
    resp = requests.get(url, headers=headers, params=params)
    print(f"  GET {path} -> {resp.status_code}")
    if resp.status_code != 200:
        print(f"  Response: {resp.text[:500]}")
    return resp.json() if resp.status_code == 200 else {}


token = generate_token()

# Get app
apps = api_get(token, "/v1/apps", {"filter[bundleId]": BUNDLE_ID})
app_id = apps["data"][0]["id"]
print(f"App ID: {app_id}\n")

# List ALL builds (no filter on version)
print("=== All builds (sorted by uploadedDate desc) ===")
builds = api_get(token, "/v1/builds", {
    "filter[app]": app_id,
    "sort": "-uploadedDate",
    "limit": "10",
})
for b in builds.get("data", []):
    a = b["attributes"]
    print(f"  ID: {b['id']}")
    print(f"  version: {a.get('version')} | processingState: {a.get('processingState')}")
    print(f"  uploadedDate: {a.get('uploadedDate')}")
    print(f"  expired: {a.get('expired')} | usesNonExemptEncryption: {a.get('usesNonExemptEncryption')}")
    print()

# List all App Store versions
print("=== App Store Versions ===")
versions = api_get(token, f"/v1/apps/{app_id}/appStoreVersions", {
    "limit": "5",
    "include": "build",
    "fields[builds]": "version,processingState,uploadedDate",
})
for v in versions.get("data", []):
    a = v["attributes"]
    print(f"  ID: {v['id']}")
    print(f"  versionString: {a.get('versionString')} | state: {a.get('appStoreState')}")
    print(f"  platform: {a.get('platform')}")
    build_rel = v.get("relationships", {}).get("build", {}).get("data")
    print(f"  build relationship: {build_rel}")
    print()

for inc in versions.get("included", []):
    if inc["type"] == "builds":
        print(f"  Included build: ID={inc['id']}, attrs={inc['attributes']}")

# Check preReleaseVersions
print("\n=== Pre-Release Versions ===")
prv = api_get(token, f"/v1/apps/{app_id}/preReleaseVersions", {
    "limit": "5",
    "include": "builds",
    "fields[builds]": "version,processingState,uploadedDate",
})
for v in prv.get("data", []):
    a = v["attributes"]
    print(f"  ID: {v['id']}")
    print(f"  version: {a.get('version')} | platform: {a.get('platform')}")
    builds_rel = v.get("relationships", {}).get("builds", {}).get("data", [])
    print(f"  builds: {builds_rel}")
    print()

for inc in prv.get("included", []):
    if inc["type"] == "builds":
        print(f"  Included build: ID={inc['id']}, version={inc['attributes'].get('version')}, "
              f"state={inc['attributes'].get('processingState')}, "
              f"uploaded={inc['attributes'].get('uploadedDate')}")

# Check review submissions
print("\n=== Review Submissions ===")
reviews = api_get(token, "/v1/reviewSubmissions", {
    "filter[app]": app_id,
    "limit": "5",
})
for r in reviews.get("data", []):
    a = r["attributes"]
    print(f"  ID: {r['id']}")
    print(f"  state: {a.get('state')} | platform: {a.get('platform')}")
    print(f"  submittedDate: {a.get('submittedDate')}")
    print()
