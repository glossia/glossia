"""Reconcile one uploaded build's TestFlight access, never upload or submit a build."""
import argparse
import base64
import json
import os
import re
import subprocess
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


ORIGIN = "https://api.appstoreconnect.apple.com"
EMAIL = "pedro@pepicrft.me"
BUNDLE = "ai.glossia.app"


class DistributionError(Exception):
    pass


class APIError(DistributionError):
    def __init__(self, status, method, path):
        self.status = status
        super().__init__(f"Apple HTTP {status}: {method} {path.split('?')[0]}. "
                         "Check API role/app access and TestFlight requirements; "
                         "retry distribution only after inspecting Apple state.")


def encoded(value):
    return base64.urlsafe_b64encode(value).rstrip(b"=")


def token(key_path, key_id, issuer):
    now = int(time.time())
    header = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    claims = {"iss": issuer, "iat": now - 10, "exp": now + 600,
              "aud": "appstoreconnect-v1"}
    message = b".".join(encoded(json.dumps(x).encode()) for x in (header, claims))
    result = subprocess.run(["openssl", "dgst", "-sha256", "-sign", str(key_path)],
                            input=message, capture_output=True, timeout=15,
                            env={"PATH": os.environ.get("PATH", "")})
    if result.returncode:
        raise DistributionError("Unable to sign ASC API request with the configured key.")
    # OpenSSL emits ASN.1 DER; ES256 JWTs require the fixed-width R || S form.
    signature = result.stdout
    try:
        if signature[0] != 0x30 or signature[1] != len(signature) - 2:
            raise ValueError()
        offset, parts = 2, []
        for _ in range(2):
            if signature[offset] != 0x02:
                raise ValueError()
            length = signature[offset + 1]
            raw = signature[offset + 2:offset + 2 + length]
            number = int.from_bytes(raw, "big")
            parts.append(number.to_bytes(32, "big"))
            offset += 2 + length
        if offset != len(signature):
            raise ValueError()
    except (IndexError, OverflowError, ValueError):
        raise DistributionError("Invalid ES256 signature from OpenSSL.") from None
    return (message + b"." + encoded(b"".join(parts))).decode()


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        raise DistributionError("Unexpected Apple API redirect; refusing to forward credentials.")


class API:
    def __init__(self, authorization):
        self.authorization = authorization
        self.opener = urllib.request.build_opener(NoRedirect())

    def request(self, method, path, payload=None):
        url = urllib.parse.urljoin(ORIGIN, path)
        parsed = urllib.parse.urlparse(url)
        if parsed.scheme != "https" or parsed.netloc != "api.appstoreconnect.apple.com":
            raise DistributionError("Refusing an unexpected API/pagination origin.")
        request = urllib.request.Request(
            url, method=method,
            data=json.dumps(payload).encode() if payload is not None else None,
            headers={"Authorization": "Bearer " + self.authorization(),
                     "Content-Type": "application/json"})
        try:
            with self.opener.open(request, timeout=20) as response:
                body = response.read()
                return json.loads(body) if body else {}
        except urllib.error.HTTPError as error:
            # Never echo response bodies, headers, credentials or a raw exception.
            raise APIError(error.code, method, path) from None
        except (urllib.error.URLError, TimeoutError, OSError, ValueError):
            raise DistributionError(
                "Apple request failed; outcome may be unknown. No request was retried. "
                "Inspect Apple state, then rerun distribution only to reconcile.") from None

    def get(self, path, **query):
        if query:
            path += "?" + urllib.parse.urlencode(query)
        return self.request("GET", path)

    def all(self, path, **query):
        response = self.get(path, **query)
        rows = list(response["data"])
        for _ in range(100):
            following = response.get("links", {}).get("next")
            if not following:
                return rows
            response = self.get(following)
            rows.extend(response["data"])
        raise DistributionError("Apple pagination exceeded its safety bound.")


def unique(rows, description):
    if len(rows) > 1:
        raise DistributionError(f"Multiple matching {description}; resolve duplicates in Apple first.")
    return rows[0] if rows else None


def wait_for_build(api, app, version, build, timeout, clock=time.monotonic, sleep=time.sleep):
    deadline = clock() + timeout
    while True:
        candidates = api.all("/v1/builds", **{"filter[app]": app, "filter[version]": build})
        matches = []
        for candidate in candidates:
            if candidate["attributes"].get("version") != build:
                continue
            prerelease = api.get(f"/v1/builds/{candidate['id']}/preReleaseVersion")["data"]
            if (prerelease["attributes"].get("version") == version
                    and prerelease["attributes"].get("platform") == "IOS"):
                matches.append(candidate)
        selected = unique(matches, "builds for the exact iOS version/build")
        if selected:
            attrs = selected["attributes"]
            state = attrs.get("processingState")
            if attrs.get("expired") or state in ("FAILED", "INVALID"):
                raise DistributionError(f"Exact build is expired or processing failed ({state}).")
            if state == "VALID":
                return selected
            if state != "PROCESSING":
                raise DistributionError(f"Unexpected Apple build processing state: {state}.")
        remaining = deadline - clock()
        if remaining <= 0:
            raise DistributionError("Timed out waiting for the exact version/build to finish processing. "
                                    "Retry distribution only; do not re-upload.")
        sleep(min(15, remaining))


def member(api, group, relationship, resource):
    return any(row["id"] == resource for row in
               api.all(f"/v1/betaGroups/{group}/relationships/{relationship}"))


def ensure_member(api, group, relationship, resource, kind):
    path = f"/v1/betaGroups/{group}/relationships/{relationship}"
    if not member(api, group, relationship, resource):
        api.request("POST", path, {"data": [{"type": kind, "id": resource}]})
    if not member(api, group, relationship, resource):
        raise DistributionError(f"Apple did not confirm the {relationship} relationship.")


def eligible_user(api, app):
    try:
        users = api.all("/v1/users", **{"filter[username]": EMAIL})
    except APIError as error:
        if error.status == 403:
            return False  # Cannot prove team access; never create or promote a team user.
        raise
    user = unique([u for u in users if u["attributes"].get("username", "").lower() == EMAIL],
                  "ASC users")
    if not user:
        return False
    attrs = user["attributes"]
    if not set(attrs.get("roles", [])) & {"ACCOUNT_HOLDER", "ADMIN", "APP_MANAGER", "DEVELOPER", "MARKETING"}:
        return False
    return attrs.get("allAppsVisible") is True or any(
        row["id"] == app for row in api.all(f"/v1/users/{user['id']}/visibleApps"))


def create_group(api, app, name, internal):
    attributes = {"name": name, "isInternalGroup": internal, "hasAccessToAllBuilds": internal}
    if not internal:
        attributes["publicLinkEnabled"] = False
    return api.request("POST", "/v1/betaGroups", {"data": {
        "type": "betaGroups", "attributes": attributes,
        "relationships": {"app": {"data": {"type": "apps", "id": app}}}}})["data"]


def distribute(api, version, build, timeout=600):
    app = unique([a for a in api.all("/v1/apps", **{"filter[bundleId]": BUNDLE})
                  if a["attributes"].get("bundleId") == BUNDLE], "Glossia apps")
    if not app:
        raise DistributionError(f"No accessible Apple app with bundle ID {BUNDLE}.")
    app_id = app["id"]
    selected = wait_for_build(api, app_id, version, build, timeout)
    build_id = selected["id"]
    groups = api.all(f"/v1/apps/{app_id}/betaGroups")
    testers = api.all("/v1/betaTesters", **{"filter[email]": EMAIL})
    tester = unique([t for t in testers if t["attributes"].get("email", "").lower() == EMAIL],
                    "beta testers")
    internals = sorted([g for g in groups if g["attributes"].get("isInternalGroup")], key=lambda g: g["id"])
    group = next((g for g in internals if tester and member(api, g["id"], "betaTesters", tester["id"])), None)
    if group is None and eligible_user(api, app_id):
        group = unique([g for g in internals if g["attributes"].get("name") == "Glossia internal"],
                       "Glossia internal groups")
        if group is None:
            group = create_group(api, app_id, "Glossia internal", True)
    if group is None:
        # Apple requires an internal group before creating an external group.
        if not internals:
            create_group(api, app_id, "Glossia internal", True)
        group = unique([g for g in groups if g["attributes"].get("name") == "Glossia beta"
                        and not g["attributes"].get("isInternalGroup")], "Glossia beta groups")
        if group is None:
            group = create_group(api, app_id, "Glossia beta", False)
        if group["attributes"].get("publicLinkEnabled"):
            raise DistributionError("Glossia beta has a public invitation link; disable it manually first.")
    group_id = group["id"]
    internal = group["attributes"].get("isInternalGroup") is True
    if tester is None:
        tester = api.request("POST", "/v1/betaTesters", {"data": {
            "type": "betaTesters", "attributes": {"email": EMAIL},
            "relationships": {"betaGroups": {"data": [{"type": "betaGroups", "id": group_id}]}}}})["data"]
    ensure_member(api, group_id, "betaTesters", tester["id"], "betaTesters")
    detail = api.get(f"/v1/builds/{build_id}/buildBetaDetail")["data"]
    state_key = "internalBuildState" if internal else "externalBuildState"
    state = detail["attributes"].get(state_key)
    ready = {"IN_BETA_TESTING", "READY_FOR_BETA_TESTING"}
    if not internal:
        ready.add("BETA_APPROVED")
    if state not in ready:
        raise DistributionError(
            f"Tester/group membership confirmed: {EMAIL}, {group_id}. "
            f"Build {version} ({build}) {state_key}={state}. "
            "In App Store Connect complete existing beta test information/export compliance "
            "and, for external testing, request TestFlight App Review as needed. "
            "No legal answers or review submissions were invented. Retry distribution only after approval.")
    if not internal and not detail["attributes"].get("autoNotifyEnabled"):
        api.request("PATCH", f"/v1/buildBetaDetails/{detail['id']}", {"data": {
            "type": "buildBetaDetails", "id": detail["id"], "attributes": {"autoNotifyEnabled": True}}})
    ensure_member(api, group_id, "builds", build_id, "builds")
    # Read back identities and membership, rather than treating a POST as proof.
    confirmed = api.get(f"/v1/betaTesters/{tester['id']}")["data"]
    confirmed_group = api.get(f"/v1/betaGroups/{group_id}")["data"]
    if (confirmed["attributes"].get("email", "").lower() != EMAIL
            or confirmed_group["attributes"].get("isInternalGroup") is not internal):
        raise DistributionError("Apple identity/group readback did not match the requested access.")
    invitation = confirmed["attributes"].get("state", "unknown")
    if not internal and invitation not in {"INVITED", "ACCEPTED", "INSTALLED"}:
        raise DistributionError(
            f"External tester {EMAIL} has invitation state {invitation}. "
            f"Group {group_id} and build {build_id} relationships are confirmed, but automatic "
            "notifications do not prove an invitation was sent. In App Store Connect send/resend "
            "the TestFlight invitation (restore revoked access if needed), then retry distribution only. "
            "No invitation request was sent or retried by this helper.")
    return (f"TestFlight relationships confirmed: {BUNDLE} (app {app_id}), {version} ({build}), "
            f"build {build_id}, {'internal' if internal else 'external'} group {group_id}, "
            f"{EMAIL} (tester {tester['id']}, invitation state "
            f"{invitation}). "
            "Invitation acceptance/device installation is not verified. Future releases reconcile this group.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version")
    parser.add_argument("build")
    parser.add_argument("--timeout", type=int, default=600)
    args = parser.parse_args()
    try:
        if (not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", args.version)
                or not re.fullmatch(r"[1-9][0-9]*(\.[0-9]+){0,2}", args.build)
                or not 1 <= args.timeout <= 1200):
            raise DistributionError("Provide an explicit stable version, positive build and timeout 1–1200s.")
        key_id = os.environ.pop("ASC_API_KEY_ID", "")
        issuer = os.environ.pop("ASC_API_ISSUER_ID", "")
        private = os.environ.pop("ASC_API_KEY_P8_BASE64", "")
        if not re.fullmatch(r"[A-Za-z0-9]+", key_id) or not re.fullmatch(r"[0-9a-fA-F-]{36}", issuer) or not private:
            raise DistributionError("The existing ASC API credentials are required.")
        with tempfile.TemporaryDirectory(prefix="glossia-testflight-") as directory:
            key_path = Path(directory) / "AuthKey.p8"
            key_path.touch(mode=0o600)
            try:
                key_path.write_bytes(base64.b64decode(private, validate=True))
            except ValueError:
                raise DistributionError("Invalid ASC private key encoding.") from None
            del private
            api = API(lambda: token(key_path, key_id, issuer))
            message = distribute(api, args.version, args.build, args.timeout)
        status = 0
    except DistributionError as error:
        message, status = f"TestFlight distribution blocked: {error}", 1
    except (KeyError, TypeError, OSError, subprocess.SubprocessError):
        message, status = ("TestFlight distribution blocked: invalid Apple response or local signing failure. "
                           "Inspect Apple state, then retry distribution only.", 1)
    print(message)
    if summary := os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(summary, "a") as output:
            output.write("\n### TestFlight distribution\n\n" + message + "\n")
    return status


if __name__ == "__main__":
    raise SystemExit(main())
