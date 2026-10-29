import datetime
import unittest
from push import configuration


class PushProvisioningTests(unittest.TestCase):
    def profile(self, environment="production"):
        return {"TeamIdentifier": ["TEAM"], "ExpirationDate": datetime.datetime(2099, 1, 1),
                "Entitlements": {"application-identifier": "TEAM.ai.glossia.app", "aps-environment": environment,
                                 "get-task-allow": environment == "development", "com.apple.developer.team-identifier": "TEAM",
                                 "keychain-access-groups": ["TEAM.*"]}}

    def test_both_environments_are_profile_derived(self):
        for value in ("development", "production"):
            environment, entitlements = configuration(self.profile(value), "ai.glossia.app")
            self.assertEqual(environment, value)
            self.assertEqual(entitlements["aps-environment"], value)
            self.assertEqual(entitlements["keychain-access-groups"], ["TEAM.ai.glossia.app"])

    def test_missing_push_wrong_identity_wildcards_and_expiry_are_rejected(self):
        profiles = [self.profile("sandbox"), self.profile(), self.profile(), self.profile()]
        profiles[1]["Entitlements"]["application-identifier"] = "TEAM.*"
        profiles[2]["ExpirationDate"] = datetime.datetime(2000, 1, 1)
        profiles[3]["Entitlements"].pop("aps-environment")
        for profile in profiles:
            with self.assertRaises(ValueError):
                configuration(profile, "ai.glossia.app")


if __name__ == "__main__":
    unittest.main()
