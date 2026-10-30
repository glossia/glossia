import base64
import contextlib
import copy
import io
import json
import os
import subprocess
import tempfile
import unittest
import urllib.error
from pathlib import Path
from unittest.mock import Mock, patch

from testflight import API, APIError, BUNDLE, EMAIL, DistributionError, distribute, main, token, wait_for_build


def resource(kind, identifier, **attributes):
    return {"type": kind, "id": identifier, "attributes": attributes}


class Apple:
    """Stateful mock: exercise read-before-write and distribution-only reruns."""
    def __init__(self):
        self.app = resource("apps", "app", bundleId=BUNDLE)
        self.builds = [resource("builds", "build", version="10.1", processingState="VALID", expired=False)]
        self.prereleases = {"build": resource("preReleaseVersions", "pre", version="0.1.1", platform="IOS")}
        self.groups = [resource("betaGroups", "internal", name="Team", isInternalGroup=True)]
        self.testers = []
        self.users = []
        self.visible = []
        self.memberships = {"internal": {"betaTesters": [], "builds": []}}
        self.detail = resource("buildBetaDetails", "detail", internalBuildState="READY_FOR_BETA_TESTING",
                               externalBuildState="READY_FOR_BETA_TESTING", autoNotifyEnabled=False)
        self.writes = []
        self.denied_users = False

    def all(self, path, **query):
        if path == "/v1/apps":
            return [self.app]
        if path == "/v1/builds":
            assert query == {"filter[app]": "app", "filter[version]": "10.1"}
            return copy.deepcopy(self.builds)
        if path == "/v1/apps/app/betaGroups":
            return copy.deepcopy(self.groups)
        if path == "/v1/betaTesters":
            assert query == {"filter[email]": EMAIL}
            return copy.deepcopy(self.testers)
        if path == "/v1/users":
            if self.denied_users:
                raise APIError(403, "GET", path)
            return self.users
        if path == "/v1/users/user/visibleApps":
            return self.visible
        parts = path.split("/")
        if len(parts) == 6 and parts[2] == "betaGroups" and parts[4] == "relationships":
            return [{"id": x} for x in self.memberships[parts[3]][parts[5]]]
        raise AssertionError(path)

    def get(self, path):
        if path.endswith("/preReleaseVersion"):
            return {"data": self.prereleases[path.split("/")[3]]}
        if path == "/v1/builds/build/buildBetaDetail":
            return {"data": copy.deepcopy(self.detail)}
        for rows in [self.testers, self.groups]:
            for row in rows:
                if path == f"/v1/{row['type']}/{row['id']}":
                    return {"data": copy.deepcopy(row)}
        raise AssertionError(path)

    def request(self, method, path, payload):
        self.writes.append((method, path, payload))
        data = payload["data"]
        if path == "/v1/betaGroups":
            group = resource("betaGroups", f"group-{len(self.groups)}", **data["attributes"])
            self.groups.append(group)
            self.memberships[group["id"]] = {"betaTesters": [], "builds": []}
            return {"data": copy.deepcopy(group)}
        if path == "/v1/betaTesters":
            tester = resource("betaTesters", "tester", **data["attributes"], state="INVITED")
            self.testers.append(tester)
            group = data["relationships"]["betaGroups"]["data"][0]["id"]
            self.memberships[group]["betaTesters"].append(tester["id"])
            return {"data": copy.deepcopy(tester)}
        if path == "/v1/buildBetaDetails/detail":
            self.detail["attributes"].update(data["attributes"])
            return {}
        parts = path.split("/")
        if len(parts) == 6 and parts[2] == "betaGroups" and parts[4] == "relationships":
            self.memberships[parts[3]][parts[5]].extend(x["id"] for x in data)
            return {}
        raise AssertionError(path)


class TestFlightTests(unittest.TestCase):
    def test_external_distribution_and_repeat_have_no_duplicate_writes(self):
        api = Apple()
        self.assertIn("relationships confirmed", distribute(api, "0.1.1", "10.1"))
        self.assertEqual(api.memberships["group-1"], {"betaTesters": ["tester"], "builds": ["build"]})
        writes = copy.deepcopy(api.writes)
        distribute(api, "0.1.1", "10.1")
        self.assertEqual(api.writes, writes)
        self.assertFalse(api.groups[-1]["attributes"]["publicLinkEnabled"])
        self.assertTrue(all("/users" not in path for _, path, _ in writes))

    def test_lost_success_response_is_reconciled_without_duplicate_creation(self):
        for uncertain_path in ("/v1/betaGroups", "/v1/betaTesters",
                               "/v1/betaGroups/group-1/relationships/builds"):
            with self.subTest(path=uncertain_path):
                api = Apple()
                original = api.request

                def lost_response(method, path, payload):
                    response = original(method, path, payload)
                    if path == uncertain_path:
                        raise DistributionError("Outcome unknown; retry distribution only.")
                    return response

                api.request = lost_response
                with self.assertRaisesRegex(DistributionError, "Outcome unknown"):
                    distribute(api, "0.1.1", "10.1")
                api.request = original
                distribute(api, "0.1.1", "10.1")
                self.assertEqual(sum(path == uncertain_path for _, path, _ in api.writes), 1)

    def test_existing_public_link_or_duplicate_external_group_is_not_reused(self):
        for duplicate in (False, True):
            api = Apple()
            api.groups.append(resource("betaGroups", "external", name="Glossia beta", isInternalGroup=False,
                                       publicLinkEnabled=not duplicate))
            if duplicate:
                api.groups.append(copy.deepcopy(api.groups[-1]))
            with self.assertRaisesRegex(DistributionError, "Multiple matching" if duplicate else "public invitation"):
                distribute(api, "0.1.1", "10.1")
            self.assertEqual(api.writes, [])

    def test_existing_internal_member_needs_no_users_permission(self):
        api = Apple()
        api.testers = [resource("betaTesters", "tester", email=EMAIL, state="ACCEPTED")]
        api.memberships["internal"]["betaTesters"] = ["tester"]
        api.denied_users = True
        self.assertIn("internal group internal", distribute(api, "0.1.1", "10.1"))
        self.assertEqual([path for _, path, _ in api.writes], ["/v1/betaGroups/internal/relationships/builds"])

    def test_eligible_user_uses_dedicated_internal_group_not_unrelated_cohort(self):
        for existing in (False, True):
            with self.subTest(existing=existing):
                api = Apple()
                api.users = [resource("users", "user", username=EMAIL, roles=["DEVELOPER"], allAppsVisible=True)]
                api.memberships["internal"] = {"betaTesters": ["other-tester"], "builds": ["other-build"]}
                unrelated = copy.deepcopy(api.memberships["internal"])
                if existing:
                    api.groups.append(resource("betaGroups", "z-dedicated", name="Glossia internal", isInternalGroup=True))
                    api.memberships["z-dedicated"] = {"betaTesters": [], "builds": []}
                distribute(api, "0.1.1", "10.1")
                self.assertEqual(api.memberships["internal"], unrelated)
                dedicated = "z-dedicated" if existing else "group-1"
                self.assertEqual(api.memberships[dedicated], {"betaTesters": ["tester"], "builds": ["build"]})
                self.assertFalse(any(path.startswith("/v1/betaGroups/internal/") for _, path, _ in api.writes))

    def test_duplicate_named_internal_groups_fail_without_writes(self):
        api = Apple()
        api.users = [resource("users", "user", username=EMAIL, roles=["DEVELOPER"], allAppsVisible=True)]
        for identifier in ("dedicated-1", "dedicated-2"):
            api.groups.append(resource("betaGroups", identifier, name="Glossia internal", isInternalGroup=True))
            api.memberships[identifier] = {"betaTesters": [], "builds": []}
        with self.assertRaisesRegex(DistributionError, "Multiple matching Glossia internal groups"):
            distribute(api, "0.1.1", "10.1")
        self.assertEqual(api.writes, [])

    def test_existing_external_relationships_do_not_prove_invitation_was_sent(self):
        for state in ("NOT_INVITED", "REVOKED", "UNKNOWN"):
            with self.subTest(state=state):
                api = Apple()
                api.groups.append(resource("betaGroups", "external", name="Glossia beta", isInternalGroup=False,
                                           publicLinkEnabled=False))
                api.testers = [resource("betaTesters", "tester", email=EMAIL, state=state)]
                api.memberships["external"] = {"betaTesters": ["tester"], "builds": ["build"]}
                with self.assertRaisesRegex(DistributionError, f"invitation state {state}"):
                    distribute(api, "0.1.1", "10.1")
                self.assertTrue(api.detail["attributes"]["autoNotifyEnabled"])
                self.assertEqual([path for _, path, _ in api.writes], ["/v1/buildBetaDetails/detail"])
                api.testers[0]["attributes"]["state"] = "INVITED"
                self.assertIn("relationships confirmed", distribute(api, "0.1.1", "10.1"))
                self.assertEqual(len(api.writes), 1)

    def test_internal_only_for_existing_eligible_user_with_app_access(self):
        for visible in (True, False):
            with self.subTest(visible=visible):
                api = Apple()
                api.users = [resource("users", "user", username=EMAIL, roles=["DEVELOPER"], allAppsVisible=False)]
                api.visible = [{"id": "app"}] if visible else []
                message = distribute(api, "0.1.1", "10.1")
                self.assertIn("internal group" if visible else "external group", message)

    def test_user_permission_denied_falls_back_without_granting_roles(self):
        api = Apple()
        api.denied_users = True
        self.assertIn("external group", distribute(api, "0.1.1", "10.1"))

    def test_external_prerequisite_group_and_approved_build(self):
        api = Apple()
        api.groups = []
        api.memberships = {}
        api.detail["attributes"]["externalBuildState"] = "BETA_APPROVED"
        distribute(api, "0.1.1", "10.1")
        self.assertEqual([g["attributes"]["isInternalGroup"] for g in api.groups], [True, False])

    def test_review_and_compliance_blockers_preserve_membership_and_retry(self):
        for state in ("READY_FOR_BETA_SUBMISSION", "MISSING_EXPORT_COMPLIANCE", "BETA_REJECTED",
                      "WAITING_FOR_BETA_REVIEW", "IN_BETA_REVIEW", "EXPIRED", "NOT_APPLICABLE"):
            with self.subTest(state=state):
                api = Apple()
                api.detail["attributes"]["externalBuildState"] = state
                with self.assertRaisesRegex(DistributionError, state):
                    distribute(api, "0.1.1", "10.1")
                self.assertEqual(api.memberships["group-1"]["betaTesters"], ["tester"])
                self.assertEqual(api.memberships["group-1"]["builds"], [])
                api.detail["attributes"]["externalBuildState"] = "READY_FOR_BETA_TESTING"
                distribute(api, "0.1.1", "10.1")
                self.assertEqual(len(api.testers), 1)
                self.assertFalse(any("Submission" in path or "Encryption" in path for _, path, _ in api.writes))

    def test_duplicate_tester_or_exact_build_fails_before_writes(self):
        for duplicate in ("tester", "build"):
            api = Apple()
            if duplicate == "tester":
                api.testers = [resource("betaTesters", str(i), email=EMAIL) for i in range(2)]
            else:
                api.builds *= 2
            with self.assertRaisesRegex(DistributionError, "Multiple matching"):
                distribute(api, "0.1.1", "10.1")
            self.assertEqual(api.writes, [])

    def test_exact_marketing_version_build_and_platform_not_latest(self):
        api = Apple()
        for identifier, version, platform, number in [("wrong-version", "0.2.0", "IOS", "10.1"),
                                                       ("wrong-platform", "0.1.1", "MAC_OS", "10.1"),
                                                       ("latest", "0.1.1", "IOS", "11.1")]:
            api.builds.insert(0, resource("builds", identifier, version=number, processingState="VALID"))
            api.prereleases[identifier] = resource("preReleaseVersions", identifier, version=version, platform=platform)
        self.assertEqual(wait_for_build(api, "app", "0.1.1", "10.1", 1)["id"], "build")

    def test_processing_delay_and_timeout_are_bounded(self):
        api = Apple()
        api.builds[0]["attributes"]["processingState"] = "PROCESSING"
        elapsed = [0]

        def sleep(seconds):
            elapsed[0] += seconds
            api.builds[0]["attributes"]["processingState"] = "VALID"

        self.assertEqual(wait_for_build(api, "app", "0.1.1", "10.1", 30,
                                       clock=lambda: elapsed[0], sleep=sleep)["id"], "build")
        self.assertEqual(elapsed[0], 15)
        api.builds = []
        with self.assertRaisesRegex(DistributionError, "Timed out"):
            wait_for_build(api, "app", "0.1.1", "10.1", 20, clock=lambda: elapsed[0],
                           sleep=lambda seconds: elapsed.__setitem__(0, elapsed[0] + seconds))
        self.assertEqual(elapsed[0], 35)

    def test_failed_invalid_expired_and_unknown_processing_stop_without_writes(self):
        for state, expired in [("FAILED", False), ("INVALID", False), ("VALID", True), ("NEW_STATE", False)]:
            api = Apple()
            api.builds[0]["attributes"].update(processingState=state, expired=expired)
            with self.assertRaises(DistributionError):
                distribute(api, "0.1.1", "10.1")
            self.assertEqual(api.writes, [])

    def test_relationship_write_readback_is_required(self):
        api = Apple()
        original = api.request

        def ignore_build(method, path, payload):
            return {} if path.endswith("/relationships/builds") else original(method, path, payload)

        api.request = ignore_build
        with self.assertRaisesRegex(DistributionError, "did not confirm"):
            distribute(api, "0.1.1", "10.1")

    def test_auth_errors_and_uncertain_post_are_never_retried_or_echoed(self):
        for failure in [urllib.error.HTTPError("url", 401, "private-response", {}, io.BytesIO(b"secret")),
                        urllib.error.HTTPError("url", 403, "private-response", {}, io.BytesIO(b"secret")),
                        urllib.error.URLError("private-response")]:
            api = API(lambda: "private-token")
            api.opener = Mock()
            api.opener.open.side_effect = failure
            with self.assertRaises(DistributionError) as raised:
                api.request("POST", "/v1/betaTesters", {"data": {}})
            self.assertEqual(api.opener.open.call_count, 1)
            self.assertNotIn("private", str(raised.exception))
            self.assertNotIn("secret", str(raised.exception))

    def test_pagination_cannot_send_authorization_to_another_host(self):
        api = API(lambda: "private-token")
        api.opener = Mock()
        with self.assertRaisesRegex(DistributionError, "unexpected"):
            api.get("https://example.com/v1/apps")
        api.opener.open.assert_not_called()

    def test_main_cleans_private_file_and_emits_safe_failure_summary(self):
        paths = []

        def blocked(api, *args):
            # Locate the private path without exposing the fixture key.
            path = next(cell.cell_contents for cell in api.authorization.__closure__
                        if isinstance(cell.cell_contents, Path))
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            self.assertNotIn("ASC_API_KEY_P8_BASE64", os.environ)
            paths.append(path)
            raise DistributionError("READY_FOR_BETA_SUBMISSION; retry distribution only.")

        with tempfile.TemporaryDirectory() as directory:
            summary = Path(directory) / "summary.md"
            env = {"ASC_API_KEY_ID": "FIXTURE", "ASC_API_ISSUER_ID": "00000000-0000-0000-0000-000000000000",
                   "ASC_API_KEY_P8_BASE64": base64.b64encode(b"fixture-private-key").decode(),
                   "GITHUB_STEP_SUMMARY": str(summary)}
            with patch.dict(os.environ, env), patch("sys.argv", ["testflight.py", "0.1.1", "10.1"]), \
                    patch("testflight.distribute", side_effect=blocked), contextlib.redirect_stdout(io.StringIO()) as output:
                self.assertEqual(main(), 1)
            self.assertIn("READY_FOR_BETA_SUBMISSION", summary.read_text())
            self.assertNotIn("fixture-private-key", output.getvalue())
            self.assertTrue(paths)
            self.assertFalse(paths[0].exists())

    def test_real_openssl_es256_signing_uses_fixed_width_signature(self):
        with tempfile.TemporaryDirectory() as directory:
            key = Path(directory) / "fixture.p8"
            subprocess.run(["openssl", "genpkey", "-algorithm", "EC", "-pkeyopt", "ec_paramgen_curve:P-256",
                            "-out", str(key)], check=True, capture_output=True)
            jwt = token(key, "FIXTURE", "00000000-0000-0000-0000-000000000000")
            header, claims, signature = jwt.split(".")
            self.assertEqual(json.loads(base64.urlsafe_b64decode(header + "==="))["alg"], "ES256")
            self.assertEqual(json.loads(base64.urlsafe_b64decode(claims + "==="))["aud"], "appstoreconnect-v1")
            raw = base64.urlsafe_b64decode(signature + "===")
            self.assertEqual(len(raw), 64)
            integers = []
            for part in (raw[:32], raw[32:]):
                value = part.lstrip(b"\0") or b"\0"
                if value[0] & 128:
                    value = b"\0" + value
                integers.append(b"\x02" + bytes([len(value)]) + value)
            contents = b"".join(integers)
            sig = Path(directory) / "fixture.sig"
            sig.write_bytes(b"\x30" + bytes([len(contents)]) + contents)
            public = Path(directory) / "fixture.pub"
            subprocess.run(["openssl", "pkey", "-in", str(key), "-pubout", "-out", str(public)],
                           check=True, capture_output=True)
            subprocess.run(["openssl", "dgst", "-sha256", "-verify", str(public), "-signature", str(sig)],
                           input=f"{header}.{claims}".encode(), check=True, capture_output=True)

    def test_workflow_separates_receipt_upload_and_distribution_retries(self):
        root = Path(__file__).resolve().parents[4]
        workflow = (root / ".github/workflows/ios-release.yml").read_text()
        upload, distribution = workflow.split("  distribute:\n")
        self.assertIn("gh release create", upload)
        self.assertNotIn("testflight.py", upload)
        self.assertIn("needs: [version, upload]", distribution)
        self.assertIn("needs.upload.result == 'success'", distribution)
        self.assertIn("!inputs.distribution_only", upload)
        self.assertIn("inputs.distribution_only", distribution)
        self.assertIn("App Store Connect upload: Glossia {version} ({build}).", distribution)
        self.assertNotIn("upload.sh", distribution)
        self.assertNotIn("bundle.sh", distribution)
        self.assertNotIn("build:ios", distribution)
        self.assertIn('testflight.py "$VERSION" "$BUILD"', distribution)


if __name__ == "__main__":
    unittest.main()
