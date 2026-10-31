#!/usr/bin/env bash
# Public-contract tests, using real ES256 signing and an offline stateful Apple API.
# jq expressions intentionally use single quotes.
# shellcheck disable=SC2016
set -euo pipefail
SOURCE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
for tool in bash jq openssl; do command -v "$tool" >/dev/null || { echo "Missing $tool" >&2; exit 1; }; done
fixture=$(mktemp -d "${TMPDIR:-/tmp}/glossia-testflight-tests.XXXXXX")
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/bin" "$fixture/tmp"
cp "$SOURCE/testflight_fixture.sh" "$fixture/bin/curl"
chmod +x "$fixture/bin/curl"
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out "$fixture/private.p8" >/dev/null 2>&1
openssl pkey -in "$fixture/private.p8" -pubout -out "$fixture/public.pem" >/dev/null 2>&1
private=$(openssl base64 -A -in "$fixture/private.p8")
export TESTFLIGHT_FIXTURE_ROOT=$fixture TESTFLIGHT_FIXTURE_STATE=$fixture/state.json
state=$TESTFLIGHT_FIXTURE_STATE
passed=0

fail() { printf 'FAIL: %s\n' "$*" >&2; cat "$fixture/output" >&2; exit 1; }
check() { jq -e "$1" "$state" >/dev/null || fail "$2"; }
edit() { jq "$@" "$state" > "$state.next"; mv "$state.next" "$state"; }
contains() { grep -Fqi -- "$1" "$fixture/output" || fail "missing output: $1"; }
no_writes() { check '.writes == []' 'failure changed Apple state'; }
done_case() { passed=$((passed + 1)); printf 'ok %s - %s\n' "$passed" "$1"; }
reset() {
  cat > "$state" <<'JSON'
{
  "apps":[{"type":"apps","id":"other-app","attributes":{"bundleId":"ai.other.app"}},
    {"type":"apps","id":"app","attributes":{"bundleId":"ai.glossia.app"}}],
  "builds":[{"type":"builds","id":"build","attributes":{"version":"10.1","processingState":"VALID","expired":false}}],
  "prereleases":{"build":{"type":"preReleaseVersions","id":"pre","attributes":{"version":"0.1.1","platform":"IOS"}}},
  "groups":[{"type":"betaGroups","id":"internal","attributes":{"name":"Team","isInternalGroup":true}}],
  "testers":[],"tester_apps":{},"users":[],"visible":[],
  "memberships":{"internal":{"betaTesters":[],"builds":[]}},
  "detail":{"type":"buildBetaDetails","id":"detail","attributes":{"internalBuildState":"READY_FOR_BETA_TESTING","externalBuildState":"READY_FOR_BETA_TESTING","autoNotifyEnabled":false}},
  "writes":[],"requests":[],"tester_reads":0,"build_reads":0,"denied_users":false
}
JSON
}
tester() {
  edit --arg invitation "$1" '.testers = [{type:"betaTesters",id:"tester",attributes:{email:"pedro@pepicrft.me",state:$invitation}}]'
}
eligible() {
  edit '.users = [{type:"users",id:"user",attributes:{username:"pedro@pepicrft.me",roles:["DEVELOPER"],allAppsVisible:true}}]'
}
external() {
  edit '.groups += [{type:"betaGroups",id:"external",attributes:{name:"Glossia beta",isInternalGroup:false,publicLinkEnabled:false}}] |
    .memberships.external = {betaTesters:["tester"],builds:["build"]}'
}
run() {
  local expected=$1 status=0 path token
  shift
  rm -f "$fixture/verified" "$fixture/header-paths" "$fixture/captured-jwt" "$fixture/fixture-error"
  edit '.tester_reads = 0 | .build_reads = 0'
  : > "$fixture/summary"
  PATH="$fixture/bin:$PATH" TMPDIR="$fixture/tmp" RUNNER_TEMP="$fixture/tmp" \
    ASC_API_KEY_ID=FIXTURE ASC_API_ISSUER_ID=00000000-0000-0000-0000-000000000000 \
    ASC_API_KEY_P8_BASE64="$private" GITHUB_STEP_SUMMARY="$fixture/summary" \
    bash "$SOURCE/testflight.sh" "$@" > "$fixture/output" 2>&1 || status=$?
  [[ ! -f "$fixture/fixture-error" ]] || fail "$(cat "$fixture/fixture-error")"
  if [[ "$expected" == success && "$status" != 0 ]] || [[ "$expected" == failure && "$status" == 0 ]]; then
    fail "expected $expected, exit status $status"
  fi
  # Assertions apply on every exit path, including uncertain writes and blockers.
  [[ -z $(find "$fixture/tmp" -mindepth 1 -print) ]] || fail 'temporary credentials were not cleaned up'
  if [[ -f "$fixture/header-paths" ]]; then
    while IFS= read -r path; do [[ ! -e "$path" ]] || fail 'authorization file survived'; done < "$fixture/header-paths"
    [[ -e "$fixture/verified" ]] || fail 'JWT signature was not verified'
  fi
  for path in "$fixture/output" "$fixture/summary"; do
    ! grep -Fq "$private" "$path" || fail 'base64 private key was logged'
    ! grep -Eq 'BEGIN PRIVATE KEY|private-response-secret|private-transport-secret|Bearer ey' "$path" || fail 'secret was logged'
    if [[ -s "$fixture/captured-jwt" ]]; then
      token=$(cat "$fixture/captured-jwt")
      ! grep -Fq "$token" "$path" || fail 'JWT was logged'
    fi
  done
}
distribute() { run "$1" 0.1.1 10.1 --timeout 1; }

reset
distribute success
contains 'relationships confirmed'
check '.memberships["group-1"] == {betaTesters:["tester"],builds:["build"]} and
  .detail.attributes.autoNotifyEnabled == true and .groups[-1].attributes.publicLinkEnabled == false' 'external access not reconciled'
check '[.requests[] | select(.method != "GET") | select(.path | test("users|Submission|Encryption"))] == []' 'unexpected privilege/legal/review write'
writes=$(jq '.writes | length' "$state")
distribute success
check ".writes | length == $writes" 'rerun made duplicate writes'
done_case 'external distribution, safe signing/cleanup, private group and idempotent rerun'

reset
edit '.builds = [
  {type:"builds",id:"wrong-version",attributes:{version:"10.1",processingState:"VALID"}},
  {type:"builds",id:"wrong-platform",attributes:{version:"10.1",processingState:"VALID"}},
  {type:"builds",id:"latest",attributes:{version:"11.1",processingState:"VALID"}}
] + .builds | .prereleases += {
  "wrong-version":{attributes:{version:"0.2.0",platform:"IOS"}},
  "wrong-platform":{attributes:{version:"0.1.1",platform:"MAC_OS"}},
  "latest":{attributes:{version:"0.1.1",platform:"IOS"}}
}'
distribute success
check '.memberships["group-1"].builds == ["build"]' 'selected latest or wrong version/platform'
done_case 'exact app, marketing version, build and iOS platform, not latest'

reset
edit '.expected_build = "20261031143005" | .builds[0].attributes.version = "20261031143005" |
  .builds += [{type:"builds",id:"newer",attributes:{version:"20261031143006",processingState:"VALID"}}] |
  .prereleases.newer = .prereleases.build'
run success 0.1.1 20261031143005 --timeout 1
check '.memberships["group-1"].builds == ["build"]' 'timestamp lookup selected a newer build'
writes=$(jq '.writes | length' "$state")
run success 0.1.1 20261031143005 --timeout 1
check ".writes | length == $writes" 'timestamp distribution rerun made duplicate writes'
done_case 'exact timestamp build distribution and idempotent retry'

for invitation in NOT_INVITED REVOKED UNKNOWN INVITED ACCEPTED INSTALLED; do
  reset; tester "$invitation"
  edit '.testers = [{type:"betaTesters",id:"other-tester",attributes:{email:"pedro@pepicrft.me",state:"ACCEPTED"}}] + .testers |
    .tester_apps["other-tester"] = "other-app"'
  case "$invitation" in
    INVITED|ACCEPTED|INSTALLED) distribute success; contains "invitation state $invitation" ;;
    *) distribute failure; contains "invitation state $invitation" ;;
  esac
  check '.memberships["group-1"].betaTesters == ["tester"] and
    ([.writes[] | select(.path == "/v1/betaTesters")] | length) == 0 and
    .testers[0].attributes.state == "ACCEPTED"' 'selected or modified tester in another app'
  done_case "app-scoped identity and explicit invitation state $invitation"
done

for invalid in missing changed-id changed-email duplicate; do
  reset; tester INVITED
  edit --arg invalid "$invalid" '.readback = $invalid'
  distribute failure
  if [[ "$invalid" == duplicate ]]; then contains 'Multiple matching'; else contains 'readback'; fi
  done_case "final app-scoped identity readback rejects $invalid"
done

reset; edit '.group_readback_changed = true'
distribute failure; contains 'readback'
done_case 'final group readback rejects changed internal/external access'

for invitation in NOT_INVITED REVOKED UNKNOWN; do
  reset; tester "$invitation"; external
  distribute failure; contains "invitation state $invitation"
  check '[.writes[].path] == ["/v1/buildBetaDetails/detail"]' 'existing relationships triggered extra writes'
  tester INVITED
  distribute success
  check '.writes | length == 1' 'invitation recovery duplicated a write'
  done_case "existing relationships do not prove invitation $invitation; later recovery"
done

reset; tester ACCEPTED
edit '.memberships.internal.betaTesters = ["tester"] | .denied_users = true'
distribute success; contains 'internal group internal'
check '[.writes[].path] == ["/v1/betaGroups/internal/relationships/builds"] and
  ([.requests[] | select(.path == "/v1/users")] | length) == 0' 'existing internal member needed users permission'
done_case 'existing internal membership does not require users permission'

for existing in false true; do
  reset; eligible
  edit '.memberships.internal = {betaTesters:["other-tester"],builds:["other-build"]}'
  dedicated=group-1
  if [[ "$existing" == true ]]; then
    dedicated=z-dedicated
    edit '.groups += [{type:"betaGroups",id:"z-dedicated",attributes:{name:"Glossia internal",isInternalGroup:true}}] |
      .memberships["z-dedicated"] = {betaTesters:[],builds:[]}'
  fi
  distribute success; contains "internal group $dedicated"
  check ".memberships[\"$dedicated\"] == {betaTesters:[\"tester\"],builds:[\"build\"]} and
    .memberships.internal == {betaTesters:[\"other-tester\"],builds:[\"other-build\"]}" 'changed unrelated internal cohort'
  done_case "eligible user uses dedicated internal group (existing=$existing)"
done

for visibility in true false; do
  reset; eligible
  edit '.users[0].attributes.allAppsVisible = false'
  if [[ "$visibility" == true ]]; then edit '.visible = [{id:"app"}]'; fi
  distribute success
  if [[ "$visibility" == true ]]; then contains 'internal group'; else contains 'external group'; fi
  done_case "internal eligibility requires app visibility ($visibility)"
done
reset; eligible
edit '.users[0].attributes.roles = ["FINANCE"]'
distribute success; contains 'external group'
done_case 'ineligible user role falls back without promoting user'
reset; edit '.denied_users = true'
distribute success; contains 'external group'
done_case 'users permission denied falls back to external'

reset
edit '.groups = [] | .memberships = {} | .detail.attributes.externalBuildState = "BETA_APPROVED"'
distribute success
check '[.groups[].attributes.isInternalGroup] == [true,false]' 'missing prerequisite internal group'
done_case 'external prerequisite internal group and approved build'

for blocker in READY_FOR_BETA_SUBMISSION MISSING_EXPORT_COMPLIANCE BETA_REJECTED WAITING_FOR_BETA_REVIEW IN_BETA_REVIEW EXPIRED NOT_APPLICABLE; do
  reset
  edit --arg blocker "$blocker" '.detail.attributes.externalBuildState = $blocker'
  distribute failure; contains "$blocker"
  grep -Fq "$blocker" "$fixture/summary" || fail 'failure absent from step summary'
  check '.memberships["group-1"] == {betaTesters:["tester"],builds:[]} and
    ([.writes[] | select(.path | test("Submission|Encryption"))] | length) == 0' 'blocker added build, answered legal questions or submitted review'
  edit '.detail.attributes.externalBuildState = "READY_FOR_BETA_TESTING"'
  distribute success
  check '.testers | length == 1' 'blocker recovery duplicated tester'
  done_case "review/compliance blocker $blocker preserves membership for recovery"
done

for duplicate in tester build app external-group internal-group user; do
  reset
  case "$duplicate" in
    tester) tester INVITED; edit '.testers += [.testers[0] | .id = "duplicate"]' ;;
    build) edit '.builds += [.builds[0]]' ;;
    app) edit '.apps += [.apps[-1] | .id = "duplicate"]' ;;
    external-group) external; edit '.groups += [.groups[-1] | .id = "duplicate"]' ;;
    internal-group)
      eligible
      edit '.groups += ["dedicated-1","dedicated-2"] | .groups |= map(if type == "string" then
        {type:"betaGroups",id:.,attributes:{name:"Glossia internal",isInternalGroup:true}} else . end) |
        .memberships["dedicated-1"] = {betaTesters:[],builds:[]} | .memberships["dedicated-2"] = {betaTesters:[],builds:[]}' ;;
    user) eligible; edit '.users += [.users[0] | .id = "duplicate"]' ;;
  esac
  distribute failure; contains 'Multiple matching'; no_writes
  done_case "duplicate $duplicate identity stops without writes"
done

reset; edit '.apps = []'
distribute failure; no_writes; contains 'ai.glossia.app'
done_case 'missing app fails without writes'
reset; external; edit '.groups[-1].attributes.publicLinkEnabled = true'
distribute failure; no_writes; contains 'public invitation'
done_case 'existing public invitation group is not reused'

for processing in FAILED INVALID NEW_STATE expired; do
  reset
  if [[ "$processing" == expired ]]; then edit '.builds[0].attributes.expired = true'
  else edit --arg processing "$processing" '.builds[0].attributes.processingState = $processing'; fi
  distribute failure; no_writes
  done_case "processing/expiry $processing stops without writes"
done
reset; edit '.builds = []'
distribute failure; contains 'Timed out'; no_writes
done_case 'missing exact build times out without writes'
reset; edit '.builds[0].attributes.processingState = "PROCESSING" | .processing_delay = true'
# Allow real signing/process startup time; the preceding case tests timeout expiry.
run success 0.1.1 10.1 --timeout 30
check '.build_reads >= 2' 'processing was not polled'
done_case 'processing build becomes valid within bounded polling'

reset; edit '.ignore_build_relationship = true'
distribute failure; contains 'confirm'
done_case 'successful write is insufficient without relationship readback'

for path in /v1/betaGroups /v1/betaTesters /v1/betaGroups/group-1/relationships/builds; do
  reset; edit --arg path "$path" '.lose_response = $path'
  distribute failure
  contains 'unknown'
  check "[.writes[] | select(.path == \"$path\")] | length == 1" 'uncertain write was retried'
  distribute success
  check "[.writes[] | select(.path == \"$path\")] | length == 1" 'recovery duplicated successful uncertain write'
  check '.memberships["group-1"] == {betaTesters:["tester"],builds:["build"]}' 'uncertain write did not recover'
  done_case "lost successful response: $path, no retry, read-before-write recovery"
done

for status in 401 403; do
  reset; edit --arg status "$status" '.http_failure = $status'
  distribute failure; contains "$status"
  check '.requests | length == 1' 'authentication request retried'
  no_writes
  done_case "HTTP $status is not retried and response secrets are not logged"
done
reset; edit '.apps_next = "https://example.invalid/v1/apps"'
distribute failure
check '[.requests[] | select(.url | startswith("https://example.invalid"))] == []' 'pagination forwarded authorization to another host'
done_case 'pagination cannot forward credentials to another origin'

for input in version build timeout-zero timeout-large; do
  reset
  case "$input" in
    version) run failure 0.1.1-rc.1 10.1 ;;
    build) run failure 0.1.1 0 ;;
    timeout-zero) run failure 0.1.1 10.1 --timeout 0 ;;
    timeout-large) run failure 0.1.1 10.1 --timeout 1201 ;;
  esac
  check '.requests == []' 'invalid CLI input reached Apple'
  done_case "invalid explicit $input rejected before network"
done

# Keep the workflow contract executable without YAML tooling or real GitHub calls.
workflow="$SOURCE/../../../../.github/workflows/ios-release.yml"
awk '/^  distribute:$/ {exit} {print}' "$workflow" > "$fixture/upload-workflow"
awk '/^  distribute:$/ {distribution=1} distribution {print}' "$workflow" > "$fixture/distribution-workflow"
workflow_has() { grep -Fq -- "$2" "$1" || fail "workflow lost: $2"; }
workflow_has "$fixture/upload-workflow" 'gh release create'
workflow_has "$fixture/upload-workflow" '!inputs.distribution_only'
! grep -Fq 'testflight.sh' "$fixture/upload-workflow" || fail 'upload job performs distribution'
workflow_has "$fixture/distribution-workflow" 'needs: [version, upload]'
workflow_has "$fixture/distribution-workflow" "needs.upload.result == 'success'"
workflow_has "$fixture/distribution-workflow" 'inputs.distribution_only'
workflow_has "$fixture/distribution-workflow" 'BUILD: ${{ needs.upload.outputs.build || inputs.build }}'
workflow_has "$fixture/distribution-workflow" 'bash mobile/native/ios/distribution/testflight.sh "$VERSION" "$BUILD"'
! grep -Eq 'upload\.sh|bundle\.sh|build:ios|gh release create' "$fixture/distribution-workflow" ||
  fail 'distribution-only job builds, uploads, or creates a receipt'
done_case 'workflow separates successful upload receipts from distribution-only retries'

# Execute the upload job's generator twice with different runner timezones.
awk '
  /^  upload:$/ {upload=1}
  upload && /^      - name: Generate UTC build number$/ {step=1; next}
  step && /^      - / {exit}
  step && /^        run: / {sub(/^        run: /, ""); print}
' "$workflow" > "$fixture/build-number.sh"
[[ -s "$fixture/build-number.sh" ]] || fail 'upload job has no build number generator'
previous=0
for timezone in Pacific/Kiritimati America/Los_Angeles; do
  before=$(date -u +%Y%m%d%H%M%S)
  TZ="$timezone" GITHUB_OUTPUT="$fixture/build-output" bash -e "$fixture/build-number.sh"
  after=$(date -u +%Y%m%d%H%M%S)
  output=$(cat "$fixture/build-output")
  [[ "$output" =~ ^number=([0-9]{14})$ ]] || fail 'build number is not a 14-digit timestamp'
  number=${BASH_REMATCH[1]}
  [[ "$number" -ge "$before" && "$number" -le "$after" && "$number" -gt "$previous" ]] ||
    fail 'upload attempt did not generate a fresh UTC timestamp'
  previous=$number
  rm "$fixture/build-output"
  sleep 1
done
done_case 'upload attempts generate fresh UTC timestamps regardless of runner timezone'

# Execute the actual workflow receipt gate, not a duplicate implementation.
awk '
  /^      - name: Require an existing exact upload receipt$/ {step=1; next}
  step && /^      - / {exit}
  step && /^        run: \|$/ {body=1; next}
  body {sub(/^          /, ""); print}
' "$workflow" > "$fixture/receipt.sh"
[[ -s "$fixture/receipt.sh" ]] || fail 'workflow has no exact upload receipt gate'
gh() {
  # VERSION is supplied by receipt_case to the extracted workflow subprocess.
  # shellcheck disable=SC2153
  [[ $# == 7 && "$1" == release && "$2" == view && "$3" == "ios@$VERSION" &&
    "$4" == --json && "$5" == body && "$6" == --jq && "$7" == .body ]] || return 97
  printf '%s\n' "$TESTFLIGHT_RECEIPT"
}
git() {
  [[ $# == 2 && "$1" == rev-parse ]] || return 97
  case "$2" in
    HEAD) printf '%s\n' "${TESTFLIGHT_CURRENT_SHA:-current}" ;;
    origin/main) printf 'current\n' ;;
    *) return 97 ;;
  esac
}
export -f gh git
receipt_case() {
  local expected=$1 receipt=$2 version=${3:-0.1.1} build=${4:-10.1} sha=${5:-current} status=0
  VERSION="$version" BUILD="$build" DISTRIBUTION_ONLY=true TESTFLIGHT_RECEIPT="$receipt" \
    TESTFLIGHT_CURRENT_SHA="$sha" GH_TOKEN=fixture GITHUB_TOKEN=fixture \
    bash -e -o pipefail "$fixture/receipt.sh" > "$fixture/output" 2>&1 || status=$?
  if [[ "$expected" == success && "$status" != 0 ]] || [[ "$expected" == failure && "$status" == 0 ]]; then
    fail "workflow receipt gate expected $expected, exit status $status"
  fi
}
receipt_case success $'Release notes\nApp Store Connect upload: Glossia 0.1.1 (10.1).\nOther notes'
receipt_case success 'App Store Connect upload: Glossia 0.1.1 (20261031143005).' 0.1.1 20261031143005
receipt_case failure 'App Store Connect upload: Glossia 0.1.1 (20261031143006).' 0.1.1 20261031143005
for receipt in '' 'App Store Connect upload: Glossia 0.1.2 (10.1).' \
  'App Store Connect upload: Glossia 0.1.1 (10.2).' \
  'prefix App Store Connect upload: Glossia 0.1.1 (10.1).' \
  'App Store Connect upload: Glossia 0.1.1 (10.1). suffix'; do
  receipt_case failure "$receipt"
done
receipt_case failure 'App Store Connect upload: Glossia 0.1.1 (10.1).' 0.1.1 10.1 stale
receipt_case failure 'App Store Connect upload: Glossia 0.1.1-rc.1 (10.1).' 0.1.1-rc.1 10.1
receipt_case failure 'App Store Connect upload: Glossia 0.1.1 (0).' 0.1.1 0
done_case 'workflow requires exact version/build receipt line, valid inputs and current main checkout'
printf 'TestFlight shell contract fixtures passed: %s cases\n' "$passed"
