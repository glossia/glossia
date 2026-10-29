import copy
import datetime
import plistlib
import tempfile
import unittest
from pathlib import Path

from profile import prepare


class AppStoreProfileTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.app = self.root / "Glossia.app"
        self.extension = self.app / "PlugIns" / "GlossiaActivity.appex"
        self.extension.mkdir(parents=True)
        for bundle, identifier in ((self.app, "ai.glossia.app"),
                                   (self.extension, "ai.glossia.app.activity")):
            (bundle / "Info.plist").write_bytes(plistlib.dumps({"CFBundleIdentifier": identifier}))
        self.profiles = [self.profile("ai.glossia.app"), self.profile("ai.glossia.app.activity")]
        self.profiles[0]["Entitlements"]["aps-environment"] = "production"

    def profile(self, identifier, team="TEAM"):
        return {"TeamIdentifier": [team], "ExpirationDate": datetime.datetime(2099, 1, 1),
                "DeveloperCertificates": [b"distribution-certificate"],
                "Entitlements": {"application-identifier": f"{team}.{identifier}",
                                 "com.apple.developer.team-identifier": team,
                                 "get-task-allow": False, "beta-reports-active": True,
                                 "keychain-access-groups": [f"{team}.*"],
                                 "unrelated-profile-permission": True}}

    def prepare(self):
        paths = [self.root / "app.plist", self.root / "extension.plist"]
        for path, profile in zip(paths, self.profiles):
            path.write_bytes(plistlib.dumps(profile))
        prepare(*paths, self.app, self.root)

    def test_separate_profiles_scope_entitlements_and_select_a_common_certificate(self):
        self.profiles[0]["DeveloperCertificates"].insert(0, b"app-only-certificate")
        self.prepare()
        app = plistlib.loads((self.root / "app.entitlements").read_bytes())
        extension = plistlib.loads((self.root / "extension.entitlements").read_bytes())
        self.assertEqual(app["application-identifier"], "TEAM.ai.glossia.app")
        self.assertEqual(extension["application-identifier"], "TEAM.ai.glossia.app.activity")
        self.assertEqual(app["keychain-access-groups"], ["TEAM.ai.glossia.app"])
        self.assertEqual(extension["keychain-access-groups"], ["TEAM.ai.glossia.app.activity"])
        self.assertEqual(app["aps-environment"], "production")
        self.assertNotIn("aps-environment", extension)
        self.assertNotIn("unrelated-profile-permission", app)
        self.assertNotIn("unrelated-profile-permission", extension)
        self.assertEqual((self.root / "certificate.cer").read_bytes(), b"distribution-certificate")
        self.assertEqual(plistlib.loads((self.app / "Info.plist").read_bytes())["GlossiaPushEnvironment"], "production")

    def test_rejects_non_store_expired_and_wrong_identity_profiles_for_either_bundle(self):
        original = copy.deepcopy(self.profiles)
        for index in (0, 1):
            for field, value in (("ProvisionedDevices", ["device"]), ("ProvisionsAllDevices", True),
                                 ("ExpirationDate", datetime.datetime(2000, 1, 1)),
                                 ("DeveloperCertificates", [])):
                with self.subTest(bundle=index, field=field):
                    self.profiles = copy.deepcopy(original)
                    self.profiles[index][field] = value
                    with self.assertRaises(ValueError):
                        self.prepare()
            for field, value in (("get-task-allow", True), ("beta-reports-active", False),
                                 ("application-identifier", "TEAM.*"),
                                 ("com.apple.developer.team-identifier", "OTHER"),
                                 ("keychain-access-groups", ["TEAM.unrelated"])):
                with self.subTest(bundle=index, entitlement=field):
                    self.profiles = copy.deepcopy(original)
                    self.profiles[index]["Entitlements"][field] = value
                    with self.assertRaises(ValueError):
                        self.prepare()

    def test_rejects_swapped_profiles_other_teams_and_different_certificates(self):
        original = copy.deepcopy(self.profiles)
        cases = [list(reversed(original)),
                 [original[0], self.profile("ai.glossia.app.activity", team="OTHER")],
                 [original[0], {**original[1], "DeveloperCertificates": [b"different-certificate"]}]]
        for profiles in cases:
            with self.subTest(profiles=profiles):
                self.profiles = profiles
                with self.assertRaises(ValueError):
                    self.prepare()

    def test_rejects_missing_or_development_push_and_unprovisioned_extensions(self):
        for environment in (None, "development"):
            with self.subTest(environment=environment):
                if environment is None:
                    self.profiles[0]["Entitlements"].pop("aps-environment")
                else:
                    self.profiles[0]["Entitlements"]["aps-environment"] = environment
                with self.assertRaises(ValueError):
                    self.prepare()
        self.profiles[0]["Entitlements"]["aps-environment"] = "production"
        (self.extension.parent / "Unconfigured.appex").mkdir()
        with self.assertRaises(ValueError):
            self.prepare()


if __name__ == "__main__":
    unittest.main()
