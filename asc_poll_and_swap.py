#!/usr/bin/env python3
"""
Poll App Store Connect for build 2 to finish processing, then swap it
onto the version and resubmit for review.
"""

import json
import time

import jwt
import requests

# --- Configuration ---
KEY_ID = "693WCL562S"
ISSUER_ID = "6c72d64b-298f-4fe8-ae61-551055fa6cde"
KEY_PATH = "/Users/linhan/.private_keys/AuthKey_693WCL562S.p8"
BUNDLE_ID = "com.fringer.app"
BASE_URL = "https://api.appstoreconnect.apple.com"
APP_ID = "6763897924"
VERSION_ID = "d98347ba-f8c6-4bea-864a-faef57c22e32"
OLD_BUILD_ID = "000aae4c-5051-4dc7-b223-1ae5aacb5aa0"
POLL_INTERVAL = 30  # seconds


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
    if resp.status_code != 200:
        print(f"  GET {path} -> {resp.status_code}: {resp.text[:300]}")
        return {}
    return resp.json()


def api_patch(token: str, path: str, data: dict) -> dict:
    url = f"{BASE_URL}{path}"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    resp = requests.patch(url, headers=headers, json=data)
    print(f"  PATCH {path} -> {resp.status_code}")
    if resp.status_code not in (200, 204):
        print(f"  Response: {resp.text[:500]}")
    return resp.json() if resp.text else {}


def api_post(token: str, path: str, data: dict) -> dict:
    url = f"{BASE_URL}{path}"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    resp = requests.post(url, headers=headers, json=data)
    print(f"  POST {path} -> {resp.status_code}")
    if resp.status_code not in (200, 201):
        print(f"  Response: {resp.text[:500]}")
    return resp.json() if resp.text else {}


def find_build2(token: str) -> dict | None:
    """Look for a build with version != 1 (i.e., build number 2)."""
    builds = api_get(token, "/v1/builds", {
        "filter[app]": APP_ID,
        "sort": "-uploadedDate",
        "limit": "10",
    })
    for b in builds.get("data", []):
        if b["id"] != OLD_BUILD_ID:
            return b
    return None


def main():
    print("=" * 60)
    print("Polling for build 2 to finish processing...")
    print("=" * 60)

    attempt = 0
    build2 = None

    while True:
        attempt += 1
        # Regenerate token each poll (in case it expires)
        token = generate_token()

        print(f"\n[Poll #{attempt}] Checking builds...")
        build2 = find_build2(token)

        if build2 is None:
            print("  Build 2 not yet visible in API. Waiting...")
            time.sleep(POLL_INTERVAL)
            continue

        state = build2["attributes"].get("processingState", "UNKNOWN")
        version = build2["attributes"].get("version", "?")
        uploaded = build2["attributes"].get("uploadedDate", "?")
        print(f"  Found build: version={version}, state={state}, uploaded={uploaded}")

        if state == "VALID":
            print("  Build 2 is VALID! Proceeding with swap.")
            break
        elif state == "INVALID":
            print("  ERROR: Build 2 processing FAILED (INVALID). Cannot proceed.")
            return
        else:
            print(f"  Still processing ({state}). Waiting {POLL_INTERVAL}s...")
            time.sleep(POLL_INTERVAL)

    build2_id = build2["id"]
    token = generate_token()

    # Step 1: Check current review submission state
    print("\n" + "=" * 60)
    print("Swapping build on version...")
    print("=" * 60)

    # Check version state
    ver_resp = api_get(token, f"/v1/appStoreVersions/{VERSION_ID}")
    ver_state = ver_resp.get("data", {}).get("attributes", {}).get("appStoreState", "UNKNOWN")
    print(f"\nVersion state: {ver_state}")

    # Try direct PATCH first
    patch_data = {
        "data": {
            "type": "appStoreVersions",
            "id": VERSION_ID,
            "relationships": {
                "build": {
                    "data": {
                        "type": "builds",
                        "id": build2_id,
                    }
                }
            },
        }
    }

    print("\nAttempting direct build swap...")
    result = api_patch(token, f"/v1/appStoreVersions/{VERSION_ID}", patch_data)

    if result.get("data"):
        new_state = result["data"]["attributes"].get("appStoreState", "?")
        new_build = result["data"].get("relationships", {}).get("build", {}).get("data", {})
        print(f"  Success! New state: {new_state}, build: {new_build}")

        if new_state == "WAITING_FOR_REVIEW":
            print("\n  Still WAITING_FOR_REVIEW -- no resubmission needed!")
            print("  Build swap is complete!")
        elif new_state == "PREPARE_FOR_SUBMISSION":
            print("\n  State changed to PREPARE_FOR_SUBMISSION. Need to resubmit.")
            # Resubmit using reviewSubmissions
            sub_data = {
                "data": {
                    "type": "reviewSubmissions",
                    "relationships": {
                        "app": {"data": {"type": "apps", "id": APP_ID}}
                    },
                    "attributes": {"platform": "MAC_OS"},
                }
            }
            new_sub = api_post(token, "/v1/reviewSubmissions", sub_data)
            sub_id = new_sub.get("data", {}).get("id")
            if sub_id:
                # Add version item
                item_data = {
                    "data": {
                        "type": "reviewSubmissionItems",
                        "relationships": {
                            "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
                            "appStoreVersion": {"data": {"type": "appStoreVersions", "id": VERSION_ID}},
                        },
                    }
                }
                api_post(token, "/v1/reviewSubmissionItems", item_data)
                # Submit
                confirm = {
                    "data": {
                        "type": "reviewSubmissions",
                        "id": sub_id,
                        "attributes": {"submitted": True},
                    }
                }
                api_patch(token, f"/v1/reviewSubmissions/{sub_id}", confirm)
                print("  Resubmitted for review!")
        return

    # Direct PATCH failed -- need to cancel submission first
    print("\nDirect swap failed. Canceling review submission first...")

    # Find active review submission
    reviews = api_get(token, "/v1/reviewSubmissions", {
        "filter[app]": APP_ID,
        "filter[state]": "WAITING_FOR_REVIEW",
    })
    active_subs = reviews.get("data", [])

    if not active_subs:
        # Also check IN_REVIEW
        reviews = api_get(token, "/v1/reviewSubmissions", {
            "filter[app]": APP_ID,
            "filter[state]": "IN_REVIEW",
        })
        active_subs = reviews.get("data", [])

    for sub in active_subs:
        sub_id = sub["id"]
        sub_state = sub["attributes"].get("state", "?")
        print(f"  Canceling submission {sub_id} (state: {sub_state})...")
        cancel = {
            "data": {
                "type": "reviewSubmissions",
                "id": sub_id,
                "attributes": {"canceled": True},
            }
        }
        api_patch(token, f"/v1/reviewSubmissions/{sub_id}", cancel)

    # Wait a moment for state to settle
    time.sleep(3)
    token = generate_token()

    # Retry the build swap
    print("\nRetrying build swap after cancellation...")
    result = api_patch(token, f"/v1/appStoreVersions/{VERSION_ID}", patch_data)
    if result.get("data"):
        print("  Build swap succeeded!")
    else:
        print("  Build swap STILL failed. You may need to do this manually.")
        return

    # Resubmit
    print("\nResubmitting for review...")
    sub_data = {
        "data": {
            "type": "reviewSubmissions",
            "relationships": {
                "app": {"data": {"type": "apps", "id": APP_ID}}
            },
            "attributes": {"platform": "MAC_OS"},
        }
    }
    new_sub = api_post(token, "/v1/reviewSubmissions", sub_data)
    sub_id = new_sub.get("data", {}).get("id")
    if sub_id:
        item_data = {
            "data": {
                "type": "reviewSubmissionItems",
                "relationships": {
                    "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
                    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": VERSION_ID}},
                },
            }
        }
        api_post(token, "/v1/reviewSubmissionItems", item_data)
        confirm = {
            "data": {
                "type": "reviewSubmissions",
                "id": sub_id,
                "attributes": {"submitted": True},
            }
        }
        api_patch(token, f"/v1/reviewSubmissions/{sub_id}", confirm)
        print("  Submitted for review!")

    print("\n" + "=" * 60)
    print("DONE! Check App Store Connect to verify.")
    print("=" * 60)


if __name__ == "__main__":
    main()
