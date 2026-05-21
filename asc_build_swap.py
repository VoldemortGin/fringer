#!/usr/bin/env python3
"""
App Store Connect: swap build for an app version.
Generates JWT, checks builds, and swaps to the latest valid build.
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


def generate_token() -> str:
    with open(KEY_PATH, "r") as f:
        private_key = f.read()

    now = int(time.time())
    payload = {
        "iss": ISSUER_ID,
        "iat": now,
        "exp": now + 1200,  # 20 minutes
        "aud": "appstoreconnect-v1",
    }
    token = jwt.encode(payload, private_key, algorithm="ES256", headers={"kid": KEY_ID})
    return token


def api_get(token: str, path: str, params: dict | None = None) -> dict:
    url = f"{BASE_URL}{path}"
    headers = {"Authorization": f"Bearer {token}"}
    resp = requests.get(url, headers=headers, params=params)
    if resp.status_code != 200:
        print(f"GET {url} -> {resp.status_code}")
        print(resp.text)
        resp.raise_for_status()
    return resp.json()


def api_patch(token: str, path: str, data: dict) -> dict:
    url = f"{BASE_URL}{path}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    resp = requests.patch(url, headers=headers, json=data)
    if resp.status_code not in (200, 204):
        print(f"PATCH {url} -> {resp.status_code}")
        print(resp.text)
        resp.raise_for_status()
    return resp.json() if resp.text else {}


def api_post(token: str, path: str, data: dict) -> dict:
    url = f"{BASE_URL}{path}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    resp = requests.post(url, headers=headers, json=data)
    if resp.status_code not in (200, 201):
        print(f"POST {url} -> {resp.status_code}")
        print(resp.text)
        resp.raise_for_status()
    return resp.json() if resp.text else {}


def api_delete(token: str, path: str) -> int:
    url = f"{BASE_URL}{path}"
    headers = {"Authorization": f"Bearer {token}"}
    resp = requests.delete(url, headers=headers)
    if resp.status_code not in (200, 204):
        print(f"DELETE {url} -> {resp.status_code}")
        print(resp.text)
        resp.raise_for_status()
    return resp.status_code


def main():
    print("=" * 60)
    print("App Store Connect — Build Swap Tool")
    print("=" * 60)

    # 1. Generate JWT
    print("\n[1] Generating JWT token...")
    token = generate_token()
    print("    Token generated successfully.")

    # 2. Get App ID
    print("\n[2] Looking up app by bundle ID:", BUNDLE_ID)
    apps = api_get(token, "/v1/apps", params={"filter[bundleId]": BUNDLE_ID})
    if not apps.get("data"):
        print("    ERROR: No app found with bundle ID", BUNDLE_ID)
        return
    app = apps["data"][0]
    app_id = app["id"]
    app_name = app["attributes"]["name"]
    print(f"    Found: {app_name} (ID: {app_id})")

    # 3. List recent builds
    print("\n[3] Fetching recent builds...")
    builds_resp = api_get(
        token,
        "/v1/builds",
        params={
            "filter[app]": app_id,
            "sort": "-uploadedDate",
            "limit": "5",
            "fields[builds]": "version,uploadedDate,processingState,minOsVersion",
        },
    )
    builds = builds_resp.get("data", [])
    print(f"    Found {len(builds)} build(s):")
    for b in builds:
        attrs = b["attributes"]
        print(
            f"    - Build version={attrs.get('version', '?')} | "
            f"state: {attrs.get('processingState', '?')} | "
            f"uploaded: {attrs.get('uploadedDate', '?')}"
        )

    # Find build 2 (the latest one, or explicitly version "2")
    build2 = None
    build1 = None
    for b in builds:
        version = b["attributes"].get("version", "")
        if version == "2":
            build2 = b
        elif version == "1":
            build1 = b

    # If no explicit version "2", check by buildNumber or just take the newest
    if build2 is None:
        # Try by buildNumber
        for b in builds:
            if b["attributes"].get("buildNumber") == "2":
                build2 = b
                break

    if build2 is None and len(builds) >= 2:
        # Take the most recent one that isn't the oldest
        build2 = builds[0]
        print(f"\n    No build explicitly numbered '2' found.")
        print(f"    Using most recent build: {build2['attributes'].get('version', '?')} "
              f"(number: {build2['attributes'].get('buildNumber', '?')})")

    if build2 is None:
        print("\n    ERROR: Could not identify build 2. Only found:")
        for b in builds:
            print(f"      version={b['attributes'].get('version')}, "
                  f"buildNumber={b['attributes'].get('buildNumber')}")
        return

    build2_state = build2["attributes"].get("processingState", "UNKNOWN")
    build2_id = build2["id"]
    print(f"\n    Target build: ID={build2_id}, state={build2_state}")

    # 4. Check if build 2 is processed
    if build2_state != "VALID":
        print(f"\n[4] Build 2 is NOT yet ready (state: {build2_state})")
        print("    You need to wait for processing to complete, then re-run this script.")
        print("    Processing states: PROCESSING -> VALID (ready) or INVALID (failed)")
        return

    print(f"\n[4] Build 2 is VALID — ready to use!")

    # 5. Get the current App Store version
    print("\n[5] Fetching current App Store version...")
    versions_resp = api_get(
        token,
        f"/v1/apps/{app_id}/appStoreVersions",
        params={
            "filter[appStoreState]": "PREPARE_FOR_SUBMISSION,WAITING_FOR_REVIEW,IN_REVIEW,DEVELOPER_REJECTED,REJECTED,READY_FOR_SALE",
            "limit": "5",
            "include": "build,appStoreVersionSubmission",
            "fields[builds]": "version,buildNumber,processingState",
        },
    )

    # If the filter was too strict, try without filter
    versions = versions_resp.get("data", [])
    if not versions:
        print("    No versions found with initial filter, trying broader search...")
        versions_resp = api_get(
            token,
            f"/v1/apps/{app_id}/appStoreVersions",
            params={
                "limit": "5",
                "include": "build,appStoreVersionSubmission",
                "fields[builds]": "version,buildNumber,processingState",
            },
        )
        versions = versions_resp.get("data", [])

    if not versions:
        print("    ERROR: No App Store versions found!")
        return

    # Show all versions
    for v in versions:
        attrs = v["attributes"]
        print(f"    Version: {attrs.get('versionString', '?')} | "
              f"state: {attrs.get('appStoreState', '?')} | "
              f"ID: {v['id']}")

    # Pick the version that's editable (not READY_FOR_SALE)
    version = None
    for v in versions:
        state = v["attributes"].get("appStoreState", "")
        if state not in ("READY_FOR_SALE", "REMOVED_FROM_SALE"):
            version = v
            break

    if version is None:
        version = versions[0]

    version_id = version["id"]
    version_state = version["attributes"].get("appStoreState", "UNKNOWN")
    version_string = version["attributes"].get("versionString", "?")
    print(f"\n    Using version: {version_string} (state: {version_state}, ID: {version_id})")

    # Check current build on this version
    current_build_rel = version.get("relationships", {}).get("build", {}).get("data")
    if current_build_rel:
        current_build_id = current_build_rel["id"]
        # Find it in included
        included = versions_resp.get("included", [])
        current_build_info = None
        for inc in included:
            if inc["type"] == "builds" and inc["id"] == current_build_id:
                current_build_info = inc
                break
        if current_build_info:
            cb_attrs = current_build_info["attributes"]
            print(f"    Current build on version: {cb_attrs.get('version', '?')} "
                  f"(number: {cb_attrs.get('buildNumber', '?')})")
        else:
            print(f"    Current build ID on version: {current_build_id}")

        if current_build_id == build2_id:
            print("\n    Build 2 is ALREADY selected for this version. Nothing to do!")
            return
    else:
        print("    No build currently selected for this version.")

    # Check if there's a submission
    submission_rel = version.get("relationships", {}).get("appStoreVersionSubmission", {}).get("data")
    submission_id = submission_rel["id"] if submission_rel else None

    # 6. Attempt to swap the build
    print(f"\n[6] Attempting to swap build on version {version_string}...")
    print(f"    Version state: {version_state}")

    # Strategy: Try PATCH first, if it fails due to submission, cancel and retry
    patch_data = {
        "data": {
            "type": "appStoreVersions",
            "id": version_id,
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

    try:
        print("    Trying direct build swap via PATCH...")
        result = api_patch(token, f"/v1/appStoreVersions/{version_id}", patch_data)
        print("    SUCCESS! Build swapped directly.")
        print(f"    Version {version_string} now uses build {build2['attributes'].get('version', '?')} "
              f"(number: {build2['attributes'].get('buildNumber', '?')})")

        # Check if we need to resubmit
        new_state = result.get("data", {}).get("attributes", {}).get("appStoreState", version_state)
        if new_state in ("PREPARE_FOR_SUBMISSION",):
            print("\n[7] Version is in PREPARE_FOR_SUBMISSION — submitting for review...")
            submit_data = {
                "data": {
                    "type": "appStoreVersionSubmissions",
                    "relationships": {
                        "appStoreVersion": {
                            "data": {
                                "type": "appStoreVersions",
                                "id": version_id,
                            }
                        }
                    },
                }
            }
            try:
                api_post(token, "/v1/appStoreVersionSubmissions", submit_data)
                print("    Submitted for review successfully!")
            except Exception as e:
                print(f"    Could not auto-submit: {e}")
                print("    You may need to submit manually from App Store Connect.")
        else:
            print(f"    Version state after swap: {new_state}")
            if new_state == "WAITING_FOR_REVIEW":
                print("    Still in review queue — no resubmission needed.")
        return

    except requests.exceptions.HTTPError as e:
        print(f"    Direct swap failed: {e}")
        print("    Will try cancel-swap-resubmit flow...")

    # 7. Cancel submission, swap build, resubmit
    if version_state in ("WAITING_FOR_REVIEW", "IN_REVIEW"):
        print(f"\n[7] Version is {version_state} — need to cancel submission first.")

        # Find the submission ID if we don't have it
        if not submission_id:
            print("    Looking up submission ID...")
            sub_resp = api_get(
                token,
                f"/v1/appStoreVersions/{version_id}/appStoreVersionSubmission",
            )
            submission_id = sub_resp.get("data", {}).get("id")

        if not submission_id:
            # Try the newer reviewSubmissions endpoint
            print("    Trying reviewSubmissions endpoint...")
            review_resp = api_get(
                token,
                "/v1/reviewSubmissions",
                params={
                    "filter[app]": app_id,
                    "filter[state]": "WAITING_FOR_REVIEW,IN_REVIEW",
                },
            )
            review_subs = review_resp.get("data", [])
            if review_subs:
                review_sub = review_subs[0]
                review_sub_id = review_sub["id"]
                review_sub_state = review_sub["attributes"].get("state", "?")
                print(f"    Found reviewSubmission: {review_sub_id} (state: {review_sub_state})")

                if review_sub_state == "WAITING_FOR_REVIEW":
                    print("    Canceling review submission...")
                    cancel_data = {
                        "data": {
                            "type": "reviewSubmissions",
                            "id": review_sub_id,
                            "attributes": {
                                "canceled": True,
                            },
                        }
                    }
                    try:
                        api_patch(token, f"/v1/reviewSubmissions/{review_sub_id}", cancel_data)
                        print("    Review submission canceled!")
                    except Exception as e:
                        print(f"    Cancel via reviewSubmissions failed: {e}")
                        # Try submitting with confirmed=false or removing
                        try:
                            cancel_data2 = {
                                "data": {
                                    "type": "reviewSubmissions",
                                    "id": review_sub_id,
                                    "attributes": {
                                        "submitted": False,
                                    },
                                }
                            }
                            api_patch(token, f"/v1/reviewSubmissions/{review_sub_id}", cancel_data2)
                            print("    Review submission canceled (method 2)!")
                        except Exception as e2:
                            print(f"    Cancel method 2 also failed: {e2}")
                            print("    You may need to cancel manually in App Store Connect.")
                            return
                elif review_sub_state == "IN_REVIEW":
                    print("    WARNING: App is currently IN_REVIEW.")
                    print("    You can still try to cancel, but Apple may not allow it.")
                    cancel_data = {
                        "data": {
                            "type": "reviewSubmissions",
                            "id": review_sub_id,
                            "attributes": {
                                "canceled": True,
                            },
                        }
                    }
                    try:
                        api_patch(token, f"/v1/reviewSubmissions/{review_sub_id}", cancel_data)
                        print("    Review canceled!")
                    except Exception as e:
                        print(f"    Could not cancel IN_REVIEW: {e}")
                        print("    You may need to wait for the review to complete or cancel manually.")
                        return
            else:
                print("    No active review submissions found.")
                print("    The version may have already been rejected or approved.")

        else:
            # Use the old appStoreVersionSubmissions endpoint
            print(f"    Deleting submission {submission_id}...")
            try:
                api_delete(token, f"/v1/appStoreVersionSubmissions/{submission_id}")
                print("    Submission deleted!")
            except Exception as e:
                print(f"    Delete failed: {e}")
                print("    Trying reviewSubmissions approach instead...")

        # Now try the build swap again
        print("\n[8] Retrying build swap after cancellation...")
        import time as _time
        _time.sleep(2)  # Brief pause to let the state settle

        try:
            result = api_patch(token, f"/v1/appStoreVersions/{version_id}", patch_data)
            print("    Build swapped successfully!")
        except Exception as e:
            print(f"    Build swap still failed: {e}")
            print("    You may need to do this manually in App Store Connect.")
            return

        # Resubmit
        print("\n[9] Resubmitting for review...")
        # Try the newer reviewSubmissions endpoint
        submit_data = {
            "data": {
                "type": "reviewSubmissions",
                "relationships": {
                    "app": {
                        "data": {
                            "type": "apps",
                            "id": app_id,
                        }
                    }
                },
                "attributes": {
                    "platform": "MAC_OS",
                },
            }
        }
        try:
            new_sub = api_post(token, "/v1/reviewSubmissions", submit_data)
            new_sub_id = new_sub.get("data", {}).get("id")
            print(f"    Created new review submission: {new_sub_id}")

            # Add the version item to the submission
            item_data = {
                "data": {
                    "type": "reviewSubmissionItems",
                    "relationships": {
                        "reviewSubmission": {
                            "data": {
                                "type": "reviewSubmissions",
                                "id": new_sub_id,
                            }
                        },
                        "appStoreVersion": {
                            "data": {
                                "type": "appStoreVersions",
                                "id": version_id,
                            }
                        },
                    },
                }
            }
            api_post(token, "/v1/reviewSubmissionItems", item_data)
            print("    Added version to review submission.")

            # Confirm/submit
            confirm_data = {
                "data": {
                    "type": "reviewSubmissions",
                    "id": new_sub_id,
                    "attributes": {
                        "submitted": True,
                    },
                }
            }
            api_patch(token, f"/v1/reviewSubmissions/{new_sub_id}", confirm_data)
            print("    Submitted for review!")
        except Exception as e:
            print(f"    Resubmit via reviewSubmissions failed: {e}")
            # Fallback to old endpoint
            print("    Trying legacy appStoreVersionSubmissions endpoint...")
            try:
                legacy_submit = {
                    "data": {
                        "type": "appStoreVersionSubmissions",
                        "relationships": {
                            "appStoreVersion": {
                                "data": {
                                    "type": "appStoreVersions",
                                    "id": version_id,
                                }
                            }
                        },
                    }
                }
                api_post(token, "/v1/appStoreVersionSubmissions", legacy_submit)
                print("    Submitted for review (legacy endpoint)!")
            except Exception as e2:
                print(f"    Legacy submit also failed: {e2}")
                print("    Please submit manually from App Store Connect.")

    else:
        print(f"\n    Version state is {version_state} — unexpected.")
        print("    Attempting build swap anyway...")
        try:
            result = api_patch(token, f"/v1/appStoreVersions/{version_id}", patch_data)
            print("    Build swapped!")
        except Exception as e:
            print(f"    Failed: {e}")

    print("\n" + "=" * 60)
    print("Done! Check App Store Connect to verify.")
    print("=" * 60)


if __name__ == "__main__":
    main()
