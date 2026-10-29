"""Derive APNs configuration only from a decoded Apple provisioning profile."""
import datetime
import fnmatch
import plistlib
import sys
from pathlib import Path


def configuration(profile, bundle_id):
    entitlements = profile.get("Entitlements", {})
    environment = entitlements.get("aps-environment")
    teams = profile.get("TeamIdentifier", [])
    team = teams[0] if len(teams) == 1 else None
    expiry = profile.get("ExpirationDate")
    if environment not in ("development", "production"):
        raise ValueError("Enable Push Notifications and regenerate the app provisioning profile")
    if not team or entitlements.get("application-identifier") != f"{team}.{bundle_id}":
        raise ValueError("An explicit provisioning profile for this app is required")
    if bundle_id != "ai.glossia.app":
        raise ValueError("Push provisioning is only supported for the production application identity")
    if not isinstance(expiry, datetime.datetime) or expiry <= datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None):
        raise ValueError("The provisioning profile has expired")
    if environment == "development" and not entitlements.get("get-task-allow"):
        raise ValueError("A development APNs profile must permit development signing")
    allowed = ("application-identifier", "com.apple.developer.team-identifier", "keychain-access-groups", "get-task-allow", "aps-environment")
    result = {key: value for key, value in entitlements.items() if key in allowed}
    group = f"{team}.{bundle_id}"
    if not any(fnmatch.fnmatchcase(group, pattern) for pattern in entitlements.get("keychain-access-groups", [])):
        raise ValueError("The profile must allow the application's Keychain group")
    result["keychain-access-groups"] = [group]
    return environment, result


def prepare(profile_path, bundle, output):
    info_path = bundle / "Info.plist"
    info = plistlib.loads(info_path.read_bytes())
    environment, entitlements = configuration(plistlib.loads(profile_path.read_bytes()), info["CFBundleIdentifier"])
    info["GlossiaPushEnvironment"] = environment
    output.write_bytes(plistlib.dumps(entitlements))
    info_path.write_bytes(plistlib.dumps(info))


if __name__ == "__main__":
    prepare(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
