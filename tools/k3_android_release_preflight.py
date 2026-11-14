#!/usr/bin/env python3
"""Fail-closed preflight for an EXISTING Care360 Google Play Android update.

Not a build or upload tool. Does not contact services or disclose credentials.
Run before a signed production AAB, and compare upload certificate with the Play Console.
"""
import ipaddress
import os
from pathlib import Path
import re
import sys
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_PACKAGE = "com.cnu.patient"


def validate_api_url(value: str) -> None:
    try:
        url = urlsplit(value)
        host = (url.hostname or "").lower()
        ipaddress.ip_address(host)
        raise ValueError("API host must be a verified public DNS name")
    except ValueError as exc:
        if str(exc) == "API host must be a verified public DNS name":
            raise
    if url.scheme != "https" or not host or "." not in host:
        raise ValueError("Production API must use a verified HTTPS DNS hostname")
    if host in {"localhost", "example.com", "example.test"} or host.endswith((".test", ".local", ".example")):
        raise ValueError("Placeholder/local API hostname is not allowed")
    if url.port not in (None, 443) or url.username or url.password or url.query or url.fragment:
        raise ValueError("Production API URL contains unexpected parameters")
    if url.path != "/api/":
        raise ValueError("Production API URL must end exactly with /api/")


def validate_version(previous: str, next_code: str) -> None:
    if not re.fullmatch(r"[1-9][0-9]*", previous or ""):
        raise ValueError("Obtain the last uploaded Android version code from Play Console")
    if not re.fullmatch(r"[1-9][0-9]*", next_code or ""):
        raise ValueError("Set the new integer Android version code")
    if int(next_code) <= int(previous):
        raise ValueError("New Android version code must exceed the Play Console version")


def validate_package(gradle_file: Path) -> None:
    gradle = gradle_file.read_text(encoding="utf-8")
    matches = re.findall(r'^\s*applicationId\s+"([^"]+)"', gradle, re.MULTILINE)
    if matches != [EXPECTED_PACKAGE]:
        raise ValueError("Android package ID does not match the existing Play listing")


def validate_signing(properties_file: Path) -> None:
    if not properties_file.is_file():
        raise ValueError("Missing android/key.properties: signed AAB blocked")
    entries = {}
    for line in properties_file.read_text(encoding="utf-8").splitlines():
        if not line.strip() or line.lstrip().startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        entries[key.strip()] = value.strip()
    for key in ("keyAlias", "keyPassword", "storePassword", "storeFile"):
        if not entries.get(key):
            raise ValueError(f"Signing property {key} is missing")
    store_file = (ROOT / "android" / "app" / entries["storeFile"]).resolve()
    if not store_file.is_file():
        raise ValueError("Android upload-keystore file is not present")
    # Existence alone does not verify that it matches the registered Play upload certificate.


def validate_android_sdk(gradle_file: Path) -> None:
    """Play requires API 36 for both new mobile apps and updates in Nov 2026."""
    gradle = gradle_file.read_text(encoding="utf-8")
    if not re.search(r"(?m)^\s*compileSdk\s+36\s*$", gradle):
        raise ValueError("Android compileSdk must be pinned to API 36 or higher")
    if not re.search(r"(?m)^\s*targetSdk\s+36\s*$", gradle):
        raise ValueError("Android targetSdk must be pinned to API 36 or higher")
    if "manifestPlaceholders[\"k3GoogleMapsApiKey\"]" not in gradle:
        raise ValueError("Android Maps API key must be injected during build")


def validate_android_manifest(manifest_file: Path) -> None:
    manifest = manifest_file.read_text(encoding="utf-8")
    if "android.permission.ACCESS_BACKGROUND_LOCATION" in manifest:
        raise ValueError("Background location must not be requested by Patient")
    if 'android:value="${k3GoogleMapsApiKey}"' not in manifest:
        raise ValueError("Missing injected Android Maps API key placeholder")
    if "Enter_Your_google_map_key" in manifest:
        raise ValueError("Placeholder Maps API key must not ship in release")


def validate_maps_key(value: str) -> None:
    if not value or value.lower().startswith(("enter_", "todo", "test", "placeholder")):
        raise ValueError("A configured Android Maps API key is required for release")
    if any(ch.isspace() for ch in value) or value.startswith("$("):
        raise ValueError("Android Maps API key is invalid")
    # This cannot verify the key's Android application and signing-fingerprint
    # restriction at Google Cloud; that must be checked by the release owner.


def main() -> int:
    try:
        if os.getenv("K3_BUILD_ENV") != "production":
            raise ValueError("K3_BUILD_ENV=production is required for Play release")
        validate_api_url(os.getenv("K3_API_BASE_URL", ""))
        validate_version(
            os.getenv("K3_PLAY_LATEST_VERSION_CODE", ""),
            os.getenv("K3_ANDROID_NEXT_VERSION_CODE", ""),
        )
        app_gradle = ROOT / "android" / "app" / "build.gradle"
        validate_package(app_gradle)
        validate_android_sdk(app_gradle)
        validate_android_manifest(ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml")
        validate_maps_key(os.getenv("K3_ANDROID_MAPS_API_KEY", ""))
        validate_signing(ROOT / "android" / "key.properties")
    except (ValueError, OSError) as exc:
        print(f"Care360 Android release BLOCKED: {exc}", file=sys.stderr)
        return 1
    print("Local Care360 Android release preflight passed. Play signing and app tests must still be verified.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
