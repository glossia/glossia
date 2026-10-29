"""Prepare the two explicit App Store profiles for Glossia's staged device bundle."""
import datetime
import fnmatch
import plistlib
import sys
from pathlib import Path

from push import configuration as push_configuration


APP_ID = "ai.glossia.mobile"
EXTENSION_ID = "ai.glossia.mobile.activity"


def configuration(profile, bundle_id):
    teams = profile.get("TeamIdentifier", [])
    team = teams[0] if len(teams) == 1 else None
    entitlements = profile.get("Entitlements", {})
    expiry = profile.get("ExpirationDate")
    if bundle_id not in (APP_ID, EXTENSION_ID):
        raise ValueError("Unexpected distribution bundle identifier")
    if (not team or entitlements.get("application-identifier") != f"{team}.{bundle_id}"
            or entitlements.get("com.apple.developer.team-identifier") != team):
        raise ValueError(f"An explicit profile for {bundle_id} is required")
    if (entitlements.get("get-task-allow") is not False
            or entitlements.get("beta-reports-active") is not True
            or "ProvisionedDevices" in profile or "ProvisionsAllDevices" in profile):
        raise ValueError("Use App Store Connect profiles, not development, Ad Hoc or enterprise")
    if not isinstance(expiry, datetime.datetime) or expiry <= datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None):
        raise ValueError("The App Store provisioning profile has expired")
    if not profile.get("DeveloperCertificates"):
        raise ValueError("The profile has no distribution certificates")

    allowed = ("application-identifier", "com.apple.developer.team-identifier",
               "get-task-allow", "beta-reports-active")
    result = {key: entitlements[key] for key in allowed}
    group = f"{team}.{bundle_id}"
    if "keychain-access-groups" in entitlements:
        if not any(fnmatch.fnmatchcase(group, pattern) for pattern in entitlements["keychain-access-groups"]):
            raise ValueError("The profile does not permit this bundle's Keychain group")
        result["keychain-access-groups"] = [group]
    if bundle_id == APP_ID:
        environment, push_entitlements = push_configuration(profile, bundle_id)
        if environment != "production":
            raise ValueError("App Store builds require production APNs")
        result.update(push_entitlements)
    return result


def prepare(app_profile_path, extension_profile_path, app, output):
    app_profile = plistlib.loads(app_profile_path.read_bytes())
    extension_profile = plistlib.loads(extension_profile_path.read_bytes())
    app_entitlements = configuration(app_profile, APP_ID)
    extension_entitlements = configuration(extension_profile, EXTENSION_ID)
    if app_profile["TeamIdentifier"] != extension_profile["TeamIdentifier"]:
        raise ValueError("App and extension must belong to the same Apple team")
    common_certificates = [cert for cert in app_profile["DeveloperCertificates"]
                           if cert in extension_profile["DeveloperCertificates"]]
    if not common_certificates:
        raise ValueError("App and extension profiles must permit the same distribution certificate")

    extension = app / "PlugIns" / "GlossiaActivity.appex"
    if set((app / "PlugIns").iterdir()) != {extension}:
        raise ValueError("Unexpected embedded extension; configure its profile before shipping")
    for bundle, bundle_id in ((app, APP_ID), (extension, EXTENSION_ID)):
        info = plistlib.loads((bundle / "Info.plist").read_bytes())
        if info["CFBundleIdentifier"] != bundle_id:
            raise ValueError(f"Expected bundle identifier {bundle_id}")
    info_path = app / "Info.plist"
    info = plistlib.loads(info_path.read_bytes())
    info["GlossiaPushEnvironment"] = "production"
    info_path.write_bytes(plistlib.dumps(info))
    (output / "app.entitlements").write_bytes(plistlib.dumps(app_entitlements))
    (output / "extension.entitlements").write_bytes(plistlib.dumps(extension_entitlements))
    (output / "certificate.cer").write_bytes(common_certificates[0])


if __name__ == "__main__":
    prepare(*(Path(argument) for argument in sys.argv[1:]))
