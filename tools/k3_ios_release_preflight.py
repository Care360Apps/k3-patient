#!/usr/bin/env python3
"""Fail closed before building an EXISTING Care360 Patient App Store update.

Use on an authorized Mac after confirming App Store Connect app ownership.
Never prints signing values, Firebase metadata, health data or credentials.
"""
import os
from pathlib import Path
import plistlib
import re
import subprocess
import sys
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_BUNDLE_ID = "com.cnu.patient"


def validate_version(previous: str, proposed: str) -> None:
    if not re.fullmatch(r"[1-9][0-9]*", previous or ""):
        raise ValueError("Read existing iOS build number from App Store Connect")
    if not re.fullmatch(r"[1-9][0-9]*", proposed or ""):
        raise ValueError("Supply an integer next iOS build number")
    if int(proposed) <= int(previous):
        raise ValueError("The new iOS build number must increase")


def validate_api_url(value: str) -> None:
    u = urlsplit(value)
    host = (u.hostname or "").lower()
    if (u.scheme != "https" or not host or "." not in host or
            u.port not in (None, 443) or u.path != "/api/" or
            u.username or u.password or u.query or u.fragment or
            host.endswith((".invalid", ".test", ".local", ".example")) or
            host in {"example.com", "localhost"} or
            re.fullmatch(r"[0-9.]+", host)):
        raise ValueError("A verified, non-placeholder production HTTPS API ending /api/ is required")


def validate_xcode(version_output: str) -> None:
    match = re.search(r"(?m)^Xcode\s+(\d+)(?:\.\d+)?\s*$", version_output)
    if not match or int(match.group(1)) < 26:
        raise ValueError("App Store submissions require Xcode 26+ with iOS 26 SDK+")


def validate_source(project_file: Path, plist_file: Path,
                    release_entitlements: Path, podfile: Path,
                    app_delegate: Path) -> None:
    project = project_file.read_text(encoding="utf-8")
    if project.count("PRODUCT_BUNDLE_IDENTIFIER = com.cnu.patient;") != 3:
        raise ValueError("Runner bundle identifier differs from the existing Patient app")
    if "CODE_SIGN_ENTITLEMENTS = Runner/RunnerRelease.entitlements;" not in project:
        raise ValueError("Release target must use separate production push entitlements")
    plist = plistlib.loads(plist_file.read_bytes())
    if plist.get("CFBundleIdentifier") != "$(PRODUCT_BUNDLE_IDENTIFIER)":
        raise ValueError("Runner must inherit the existing bundle ID")
    for key in ("NSCameraUsageDescription", "NSMicrophoneUsageDescription",
                "NSPhotoLibraryUsageDescription", "NSLocationWhenInUseUsageDescription"):
        if not plist.get(key):
            raise ValueError("Missing an iOS sensitive-permission usage description")
    entitlements = plistlib.loads(release_entitlements.read_bytes())
    if entitlements.get("aps-environment") != "production":
        raise ValueError("Release APNs entitlement must use production")
    pods = podfile.read_text(encoding="utf-8")
    if "platform :ios, '14.0'" not in pods:
        raise ValueError("iOS Podfile minimum must match tested deployment target")
    delegate = app_delegate.read_text(encoding="utf-8")
    if "print(\"APNs token" in delegate or "print(\"APNs" in delegate:
        raise ValueError("APNs tokens must not be printed")
    if "requestAuthorization(" in delegate:
        raise ValueError("Notification permission must not be requested on launch")


def validate_firebase_ios(plist_path: Path, approved_project: str) -> None:
    if not plist_path.is_file():
        raise ValueError("Production iOS Firebase plist is missing")
    obj = plistlib.loads(plist_path.read_bytes())
    if obj.get("BUNDLE_ID") != EXPECTED_BUNDLE_ID:
        raise ValueError("Firebase iOS bundle ID must match existing App Store app")
    if not approved_project or obj.get("PROJECT_ID") != approved_project:
        raise ValueError("Firebase project does not match verified production project")
    for field in ("API_KEY", "GOOGLE_APP_ID", "GCM_SENDER_ID", "PROJECT_ID"):
        if not obj.get(field):
            raise ValueError("Production Firebase iOS configuration is incomplete")


def validate_native_maps_config(private_xcconfig: Path, expected: str) -> None:
    if not expected or not re.fullmatch(r"[A-Za-z0-9_-]+", expected):
        raise ValueError("Set an approved native iOS Maps key")
    if not private_xcconfig.is_file():
        raise ValueError("Create untracked ios/Flutter/Care360PrivateRelease.xcconfig for native Maps")
    content = private_xcconfig.read_text(encoding="utf-8")
    found = re.search(r"(?m)^K3_GOOGLE_MAPS_API_KEY\s*=\s*([A-Za-z0-9_-]+)\s*$", content)
    if not found or found.group(1) != expected:
        raise ValueError("Private Release.xcconfig Maps key does not match approved key")


def main() -> int:
    try:
        if os.getenv("K3_BUILD_ENV") != "production":
            raise ValueError("K3_BUILD_ENV=production is required")
        validate_version(os.getenv("K3_IOS_LATEST_BUILD_NUMBER", ""),
                         os.getenv("K3_IOS_NEXT_BUILD_NUMBER", ""))
        validate_api_url(os.getenv("K3_API_BASE_URL", ""))
        validate_native_maps_config(
            ROOT / "ios/Flutter/Care360PrivateRelease.xcconfig",
            os.getenv("K3_IOS_GOOGLE_MAPS_API_KEY", ""),
        )
        validate_source(
            ROOT / "ios/Runner.xcodeproj/project.pbxproj",
            ROOT / "ios/Runner/Info.plist",
            ROOT / "ios/Runner/RunnerRelease.entitlements",
            ROOT / "ios/Podfile",
            ROOT / "ios/Runner/AppDelegate.swift",
        )
        configured_team = os.getenv("K3_IOS_DEVELOPMENT_TEAM", "").strip()
        project = (ROOT / "ios/Runner.xcodeproj/project.pbxproj").read_text(encoding="utf-8")
        if not configured_team or f"DEVELOPMENT_TEAM = {configured_team};" not in project:
            raise ValueError("Verify Apple Team ID and current signing ownership")
        validate_firebase_ios(
            Path(os.getenv("K3_IOS_FIREBASE_PLIST_PATH", "")),
            os.getenv("K3_PRODUCTION_FIREBASE_PROJECT_ID", ""),
        )
        try:
            current_xcode = subprocess.check_output(
                ["xcodebuild", "-version"], text=True, stderr=subprocess.DEVNULL)
        except (OSError, subprocess.CalledProcessError):
            raise ValueError("An authorized Mac with Xcode 26+ is required")
        validate_xcode(current_xcode)
    except (ValueError, OSError, TypeError, plistlib.InvalidFileException) as exc:
        print(f"Care360 iOS App Store release BLOCKED: {exc}", file=sys.stderr)
        return 1
    print("Care360 iOS static preflight passed; signing, functionality and store review still require verification.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
