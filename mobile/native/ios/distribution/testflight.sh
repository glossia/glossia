#!/usr/bin/env bash
# Reconcile one uploaded TestFlight build. Never upload, submit reviews, or grant team roles.
set -euo pipefail
set +x
umask 077

EMAIL=pedro@pepicrft.me
BUNDLE=ai.glossia.app
ORIGIN=https://api.appstoreconnect.apple.com

report() {
  printf '%s\n' "$1"
  if [[ -n ${GITHUB_STEP_SUMMARY:-} ]]; then
    printf '\n### TestFlight distribution\n\n%s\n' "$1" >> "$GITHUB_STEP_SUMMARY"
  fi
}

fail() {
  report "TestFlight distribution blocked: $1" >&2
  exit 1
}

base64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

authorization() {
  local now header claims message part count=0
  now=$(date +%s)
  header=$(jq -cn --arg kid "$ASC_API_KEY_ID" '{alg:"ES256",kid:$kid,typ:"JWT"}' | base64url)
  claims=$(jq -cn --arg iss "$ASC_API_ISSUER_ID" --argjson now "$now" \
    '{iss:$iss,iat:($now-10),exp:($now+600),aud:"appstoreconnect-v1"}' | base64url)
  message="$header.$claims"
  printf '%s' "$message" | openssl dgst -sha256 -sign "$temporary/AuthKey.p8" \
    -out "$temporary/signature.der" 2>/dev/null || fail 'Unable to sign the ASC request.'
  openssl asn1parse -inform DER -in "$temporary/signature.der" 2>/dev/null \
    | awk -F: '/INTEGER/ {gsub(/[[:space:]]/, "", $NF); print $NF}' \
    > "$temporary/integers" || fail 'Invalid ES256 signature from OpenSSL.'
  : > "$temporary/signature.raw"
  # JWT ES256 uses fixed-width R || S, not OpenSSL's DER signature.
  while IFS= read -r part; do
    while [[ ${#part} -gt 64 && ${part:0:2} == 00 ]]; do part=${part:2}; done
    [[ "$part" =~ ^[0-9A-Fa-f]{1,64}$ ]] || fail 'Invalid ES256 signature from OpenSSL.'
    printf '%064s' "$part" | tr ' ' 0 | xxd -r -p >> "$temporary/signature.raw"
    count=$((count + 1))
  done < "$temporary/integers"
  [[ "$count" == 2 ]] || fail 'Invalid ES256 signature from OpenSSL.'
  printf 'Authorization: Bearer %s.%s\nContent-Type: application/json\n' \
    "$message" "$(base64url < "$temporary/signature.raw")" > "$temporary/headers"
}

api_request() {
  local method=$1 path=$2 payload=${3:-} status
  local args=(--disable --silent --show-error --globoff --connect-timeout 10 --max-time 30
    --request "$method" --header "@$temporary/headers" --output "$temporary/response.json"
    --write-out '%{http_code}')
  case "$path" in
    "$ORIGIN"/v1/*) path=${path#"$ORIGIN"} ;;
    /v1/*) ;;
    *) fail 'Refusing an unexpected API/pagination origin.' ;;
  esac
  authorization || return $?
  [[ -z "$payload" ]] || args+=(--data-binary "$payload")
  # No redirects, .curlrc, automatic retries, or bearer tokens in process arguments.
  status=$(curl "${args[@]}" "$ORIGIN$path" 2>/dev/null) || \
    fail 'Apple request failed; outcome may be unknown. No request was retried. Inspect Apple state, then retry distribution only.'
  case "$status" in
    2??) ;;
    403)
      # Insufficient permission to list users is not proof of internal eligibility.
      [[ "$method" != GET || "$path" != /v1/users\?* ]] || return 43
      fail "Apple HTTP 403: $method ${path%%\?*}. Check API role/app access before retrying distribution only."
      ;;
    *) fail "Apple HTTP $status: $method ${path%%\?*}. Inspect Apple permissions/state, then retry distribution only." ;;
  esac
  if [[ ! -s "$temporary/response.json" ]]; then
    printf '{}\n'
  else
    jq -ce 'select(type == "object")' "$temporary/response.json" 2>/dev/null \
      || fail 'Invalid Apple response; inspect Apple state before retrying distribution only.'
  fi
}

api_list() {
  local path=$1 query response next rows='[]' page
  shift
  if [[ $# -gt 0 ]]; then
    query=$(jq -nr --args '$ARGS.positional | map(index("=") as $i |
      "\(.[0:$i] | @uri)=\(.[($i+1):] | @uri)") | join("&")' -- "$@")
    path="$path?$query"
  fi
  for ((page=0; page<100; page++)); do
    response=$(api_request GET "$path") || return $?
    jq -e '.data | type == "array"' <<< "$response" >/dev/null 2>&1 \
      || fail 'Invalid Apple list response.'
    rows=$(jq -cn --argjson rows "$rows" --argjson response "$response" '$rows + $response.data')
    next=$(jq -r '.links.next // empty' <<< "$response")
    if [[ -z "$next" ]]; then printf '%s\n' "$rows"; return; fi
    path=$next
  done
  fail 'Apple pagination exceeded its safety bound.'
}

unique() {
  [[ $(jq 'length' <<< "$1") -le 1 ]] || fail "Multiple matching $2; resolve duplicates in Apple first."
  jq -c '.[0] // null' <<< "$1"
}

wait_for_build() {
  local deadline=$((SECONDS + timeout)) candidates matches candidate prerelease selected state remaining
  while :; do
    candidates=$(api_list /v1/builds "filter[app]=$app_id" "filter[version]=$build") || exit $?
    matches='[]'
    while IFS= read -r candidate; do
      prerelease=$(api_request GET "/v1/builds/$(jq -r '.id' <<< "$candidate")/preReleaseVersion") || exit $?
      if jq -e --arg version "$version" \
        '.data.attributes.version == $version and .data.attributes.platform == "IOS"' <<< "$prerelease" >/dev/null; then
        matches=$(jq -cn --argjson matches "$matches" --argjson candidate "$candidate" '$matches + [$candidate]')
      fi
    done < <(jq -c --arg build "$build" '.[] | select(.attributes.version == $build)' <<< "$candidates")
    selected=$(unique "$matches" 'builds for the exact iOS version/build') || exit $?
    if [[ "$selected" != null ]]; then
      state=$(jq -r '.attributes.processingState' <<< "$selected")
      if [[ $(jq -r '.attributes.expired // false' <<< "$selected") == true || "$state" == FAILED || "$state" == INVALID ]]; then
        fail "Exact build is expired or processing failed ($state)."
      fi
      case "$state" in
        VALID) printf '%s\n' "$selected"; return ;;
        PROCESSING) ;;
        *) fail "Unexpected Apple build processing state: $state." ;;
      esac
    fi
    remaining=$((deadline - SECONDS))
    [[ "$remaining" -gt 0 ]] || fail 'Timed out waiting for the exact version/build. Retry distribution only; do not re-upload.'
    [[ "$remaining" -le 15 ]] || remaining=15
    sleep "$remaining"
  done
}

member() {
  local rows
  rows=$(api_list "/v1/betaGroups/$1/relationships/$2") || exit $?
  jq -e --arg id "$3" 'any(.[]; .id == $id)' <<< "$rows" >/dev/null
}

ensure_member() {
  local path="/v1/betaGroups/$1/relationships/$2" payload
  if ! member "$1" "$2" "$3"; then
    payload=$(jq -cn --arg id "$3" --arg type "$4" '{data:[{type:$type,id:$id}]}')
    api_request POST "$path" "$payload" >/dev/null || exit $?
  fi
  member "$1" "$2" "$3" || fail "Apple did not confirm the $2 relationship."
}

eligible_user() {
  local users user status visible
  if users=$(api_list /v1/users "filter[username]=$EMAIL"); then
    user=$(unique "$(jq -c --arg email "$EMAIL" '[.[] | select((.attributes.username // "" | ascii_downcase) == $email)]' <<< "$users")" 'ASC users') || exit $?
  else
    status=$?
    [[ "$status" != 43 ]] || return 1
    exit "$status"
  fi
  [[ "$user" != null ]] || return 1
  jq -e '.attributes.roles | any(. == "ACCOUNT_HOLDER" or . == "ADMIN" or . == "APP_MANAGER" or . == "DEVELOPER" or . == "MARKETING")' \
    <<< "$user" >/dev/null || return 1
  [[ $(jq -r '.attributes.allAppsVisible' <<< "$user") != true ]] || return 0
  visible=$(api_list "/v1/users/$(jq -r '.id' <<< "$user")/visibleApps") || exit $?
  jq -e --arg app "$app_id" 'any(.[]; .id == $app)' <<< "$visible" >/dev/null
}

create_group() {
  local payload response
  payload=$(jq -cn --arg app "$app_id" --arg name "$1" --argjson internal "$2" \
    '{data:{type:"betaGroups",attributes:({name:$name,isInternalGroup:$internal,hasAccessToAllBuilds:$internal} +
      if $internal then {} else {publicLinkEnabled:false} end),relationships:{app:{data:{type:"apps",id:$app}}}}}')
  response=$(api_request POST /v1/betaGroups "$payload") || exit $?
  jq -ce '.data | select(type == "object")' <<< "$response" || fail 'Invalid Apple group response.'
}

tester_list() {
  local rows
  rows=$(api_list /v1/betaTesters "filter[email]=$EMAIL" "filter[apps]=$app_id" \
    'fields[betaTesters]=email,inviteType,state') || exit $?
  unique "$(jq -c --arg email "$EMAIL" '[.[] | select((.attributes.email // "" | ascii_downcase) == $email)]' <<< "$rows")" 'beta testers'
}

distribute() {
  local apps app selected groups tester internals group=null candidate users group_id internal payload
  local detail state_key state confirmed confirmed_group invitation
  apps=$(api_list /v1/apps "filter[bundleId]=$BUNDLE") || exit $?
  app=$(unique "$(jq -c --arg bundle "$BUNDLE" '[.[] | select(.attributes.bundleId == $bundle)]' <<< "$apps")" 'Glossia apps') || exit $?
  [[ "$app" != null ]] || fail "No accessible Apple app with bundle ID $BUNDLE."
  app_id=$(jq -r '.id' <<< "$app")
  selected=$(wait_for_build) || exit $?
  build_id=$(jq -r '.id' <<< "$selected")
  groups=$(api_list "/v1/apps/$app_id/betaGroups") || exit $?
  tester=$(tester_list) || exit $?
  internals=$(jq -c '[.[] | select(.attributes.isInternalGroup == true)] | sort_by(.id)' <<< "$groups")
  if [[ "$tester" != null ]]; then
    while IFS= read -r candidate; do
      if member "$(jq -r '.id' <<< "$candidate")" betaTesters "$(jq -r '.id' <<< "$tester")"; then
        group=$candidate; break
      fi
    done < <(jq -c '.[]' <<< "$internals")
  fi
  if [[ "$group" == null ]] && eligible_user; then
    group=$(unique "$(jq -c '[.[] | select(.attributes.name == "Glossia internal")]' <<< "$internals")" 'Glossia internal groups') || exit $?
    if [[ "$group" == null ]]; then group=$(create_group 'Glossia internal' true) || exit $?; fi
  fi
  if [[ "$group" == null ]]; then
    # Apple requires an internal group before an external group can be created.
    if [[ $(jq 'length' <<< "$internals") == 0 ]]; then create_group 'Glossia internal' true >/dev/null || exit $?; fi
    group=$(unique "$(jq -c '[.[] | select(.attributes.name == "Glossia beta" and .attributes.isInternalGroup == false)]' <<< "$groups")" 'Glossia beta groups') || exit $?
    if [[ "$group" == null ]]; then group=$(create_group 'Glossia beta' false) || exit $?; fi
    [[ $(jq -r '.attributes.publicLinkEnabled // false' <<< "$group") != true ]] \
      || fail 'Glossia beta has a public invitation link; disable it manually first.'
  fi
  group_id=$(jq -r '.id' <<< "$group")
  internal=$(jq -r '.attributes.isInternalGroup' <<< "$group")
  if [[ "$tester" == null ]]; then
    payload=$(jq -cn --arg email "$EMAIL" --arg group "$group_id" \
      '{data:{type:"betaTesters",attributes:{email:$email},relationships:{betaGroups:{data:[{type:"betaGroups",id:$group}]}}}}')
    tester=$(api_request POST /v1/betaTesters "$payload") || exit $?
    tester=$(jq -ce '.data | select(type == "object")' <<< "$tester") || fail 'Invalid Apple tester response.'
  fi
  ensure_member "$group_id" betaTesters "$(jq -r '.id' <<< "$tester")" betaTesters
  detail=$(api_request GET "/v1/builds/$build_id/buildBetaDetail") || exit $?
  state_key=externalBuildState
  [[ "$internal" != true ]] || state_key=internalBuildState
  state=$(jq -r --arg key "$state_key" '.data.attributes[$key]' <<< "$detail")
  case "$state" in
    IN_BETA_TESTING|READY_FOR_BETA_TESTING) ;;
    BETA_APPROVED) [[ "$internal" != true ]] || fail "Unexpected internal build state: $state." ;;
    *) fail "Tester/group membership confirmed: $EMAIL, $group_id. Build $version ($build) $state_key=$state. Complete beta information/export compliance and external TestFlight review in App Store Connect. No legal answers or review submissions were invented. Retry distribution only after approval." ;;
  esac
  if [[ "$internal" != true && $(jq -r '.data.attributes.autoNotifyEnabled // false' <<< "$detail") != true ]]; then
    payload=$(jq -cn --arg id "$(jq -r '.data.id' <<< "$detail")" \
      '{data:{type:"buildBetaDetails",id:$id,attributes:{autoNotifyEnabled:true}}}')
    api_request PATCH "/v1/buildBetaDetails/$(jq -r '.data.id' <<< "$detail")" "$payload" >/dev/null || exit $?
  fi
  ensure_member "$group_id" builds "$build_id" builds
  # App-scoped lists expose invitation state; individual tester reads can return null.
  confirmed=$(tester_list) || exit $?
  confirmed_group=$(api_request GET "/v1/betaGroups/$group_id") || exit $?
  [[ "$confirmed" != null && $(jq -r '.id' <<< "$confirmed") == "$(jq -r '.id' <<< "$tester")" && \
    $(jq -r '.data.attributes.isInternalGroup' <<< "$confirmed_group") == "$internal" ]] \
    || fail 'Apple identity/group readback did not match the requested access.'
  invitation=$(jq -r '.attributes.state // "unknown"' <<< "$confirmed")
  if [[ "$internal" != true ]]; then
    case "$invitation" in
      INVITED|ACCEPTED|INSTALLED) ;;
      *) fail "External tester $EMAIL has invitation state $invitation. Group and build relationships are confirmed, but notifications do not prove invitation delivery. Send/resend the invitation or restore revoked access in App Store Connect, then retry distribution only. No invitation request was sent by this helper." ;;
    esac
  fi
  [[ "$internal" != true ]] && internal=external || internal=internal
  report "TestFlight relationships confirmed: $BUNDLE (app $app_id), $version ($build), build $build_id, $internal group $group_id, $EMAIL (tester $(jq -r '.id' <<< "$confirmed"), invitation state $invitation). Acceptance/device installation is not verified. Future releases reconcile this group."
}

[[ $# == 2 || ($# == 4 && $3 == --timeout) ]] || fail 'Usage: testflight.sh VERSION BUILD [--timeout 1..1200]'
version=$1 build=$2 timeout=${4:-600}
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && "$build" =~ ^[1-9][0-9]*(\.[0-9]+){0,2}$ && \
  "$timeout" =~ ^[1-9][0-9]{0,3}$ ]] || fail 'Provide an explicit stable version, positive build, and timeout 1..1200.'
[[ "$timeout" -le 1200 ]] || fail 'Timeout must be between 1 and 1200 seconds.'
[[ ${ASC_API_KEY_ID:-} =~ ^[A-Za-z0-9]+$ && ${ASC_API_ISSUER_ID:-} =~ ^[0-9a-fA-F-]{36}$ && \
  -n ${ASC_API_KEY_P8_BASE64:-} ]] || fail 'The existing ASC API credentials are required.'
temporary=$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/glossia-testflight.XXXXXX")
trap 'rm -rf "$temporary"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP
printf '%s' "$ASC_API_KEY_P8_BASE64" | base64 --decode > "$temporary/AuthKey.p8" 2>/dev/null \
  || fail 'Invalid ASC private key encoding.'
unset ASC_API_KEY_P8_BASE64
openssl pkey -in "$temporary/AuthKey.p8" -passin pass: -noout 2>/dev/null \
  || fail 'Invalid ASC signing key.'
distribute || exit $?
