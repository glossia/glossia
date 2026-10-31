#!/usr/bin/env bash
# A stateful, offline App Store Connect curl replacement. No production hooks.
# jq expressions intentionally use single quotes.
# shellcheck disable=SC2016
set -euo pipefail
state=${TESTFLIGHT_FIXTURE_STATE:?}
root=${TESTFLIGHT_FIXTURE_ROOT:?}
method=GET output='' headers='' payload='' url=''
while (($#)); do
  case "$1" in
    --disable|--silent|--show-error|--globoff) shift ;;
    --connect-timeout|--max-time|--write-out) shift 2 ;;
    --request) method=$2; shift 2 ;;
    --header) headers=${2#@}; shift 2 ;;
    --output) output=$2; shift 2 ;;
    --data-binary) payload=$2; shift 2 ;;
    https://*) url=$1; shift ;;
    *) echo 'Unexpected curl option in TestFlight fixture' >&2; exit 97 ;;
  esac
done
[[ -n "$url" && -n "$output" && -f "$headers" ]] || exit 97

update() {
  jq "$@" "$state" > "$state.next"
  mv "$state.next" "$state"
}
respond() {
  printf '%s\n' "$2" > "$output"
  printf '%s' "$1"
  exit 0
}
fail_fixture() {
  printf 'TestFlight fixture: %s\n' "$*" > "$root/fixture-error"
  exit 97
}

# The private key must have been consumed before spawning any network process.
[[ ! ${ASC_API_KEY_P8_BASE64+x} ]] || fail_fixture 'private key inherited by curl'
[[ $(find "$headers" \( -perm -0040 -o -perm -0004 \) -print) == '' ]] ||
  fail_fixture 'readable authorization file'
[[ $(find "$(dirname "$headers")" -name '*.p8' \( -perm -0040 -o -perm -0004 \) -print) == '' ]] ||
  fail_fixture 'readable private key'
printf '%s\n' "$headers" >> "$root/header-paths"

# Verify a real ES256 signature, not merely JWT shape. Only once per invocation.
if [[ ! -e "$root/verified" ]]; then
  jwt=$(sed -n 's/^[Aa]uthorization: Bearer //p' "$headers" | tr -d '\r')
  [[ "$jwt" == *.*.* ]] || fail_fixture 'missing Bearer JWT'
  header=${jwt%%.*}; rest=${jwt#*.}; claims=${rest%%.*}; signature=${rest#*.}
  decode() {
    local encoded=$1
    while ((${#encoded} % 4)); do encoded="${encoded}="; done
    printf '%s' "$encoded" | tr '_-' '/+' | openssl base64 -d -A
  }
  decode "$header" > "$root/jwt-header"
  decode "$claims" > "$root/jwt-claims"
  decode "$signature" > "$root/jwt-raw"
  jq -e '.alg == "ES256" and .kid == "FIXTURE" and .typ == "JWT"' "$root/jwt-header" >/dev/null ||
    fail_fixture 'JWT header'
  jq -e --argjson now "$(date +%s)" '
    .iss == "00000000-0000-0000-0000-000000000000" and .aud == "appstoreconnect-v1"
    and .iat <= $now and .iat >= ($now - 60) and .exp > $now and .exp <= ($now + 1200)
  ' "$root/jwt-claims" >/dev/null || fail_fixture 'JWT claims'
  [[ $(wc -c < "$root/jwt-raw" | tr -d ' ') == 64 ]] || fail_fixture 'JWT signature is not 64 bytes'
  hex=$(od -An -v -tx1 "$root/jwt-raw" | tr -d ' \n')
  {
    printf 'asn1=SEQUENCE:signature\n[signature]\n'
    printf 'r=INTEGER:0x%s\ns=INTEGER:0x%s\n' "${hex:0:64}" "${hex:64:64}"
  } > "$root/signature.cnf"
  openssl asn1parse -genconf "$root/signature.cnf" -out "$root/signature.der" >/dev/null 2>&1 ||
    fail_fixture 'cannot encode JWT signature'
  printf '%s.%s' "$header" "$claims" > "$root/jwt-message"
  openssl dgst -sha256 -verify "$root/public.pem" -signature "$root/signature.der" \
    "$root/jwt-message" > /dev/null 2>&1 || fail_fixture 'invalid JWT signature'
  printf '%s\n' "$jwt" > "$root/captured-jwt"
  touch "$root/verified"
fi

# Decode only percent triplets. Never interpret literal backslashes in a URL.
decode_url() {
  local rest=$1 char pair
  while [[ -n "$rest" ]]; do
    char=${rest:0:1}; rest=${rest:1}
    if [[ "$char" == '%' && "$rest" == [[:xdigit:]][[:xdigit:]]* ]]; then
      pair=${rest:0:2}; rest=${rest:2}
      printf '%b' "\\x$pair"
    elif [[ "$char" == '+' ]]; then
      printf ' '
    else
      printf '%s' "$char"
    fi
  done
}
url=$(decode_url "$url")
path=${url#https://api.appstoreconnect.apple.com}
path=${path%%\?*}
update --arg method "$method" --arg url "$url" --arg path "$path" \
  '.requests += [{method:$method,url:$url,path:$path}]'
[[ "$url" == https://api.appstoreconnect.apple.com/* ]] || respond 418 '{"errors":[{"detail":"private-response-secret"}]}'

status=$(jq -r '.http_failure // empty' "$state")
[[ -z "$status" ]] || respond "$status" '{"errors":[{"detail":"private-response-secret"}]}'
if [[ "$method" == GET ]]; then
  case "$path" in
    /v1/apps)
      respond 200 "$(jq '{data:.apps,links:{next:(.apps_next // null)}}' "$state")" ;;
    /v1/builds)
      expected_build=$(jq -r '.expected_build // "10.1"' "$state")
      [[ "$url" == *'filter[app]=app'* && "$url" == *"filter[version]=$expected_build"* ]] ||
        fail_fixture 'build query is not scoped to the app and exact build'
      update '.build_reads += 1 | if .processing_delay and .build_reads > 1 then .builds[0].attributes.processingState = "VALID" else . end'
      respond 200 "$(jq '{data:.builds}' "$state")" ;;
    /v1/builds/*/preReleaseVersion)
      identifier=${path#/v1/builds/}; identifier=${identifier%/preReleaseVersion}
      respond 200 "$(jq --arg id "$identifier" '{data:.prereleases[$id]}' "$state")" ;;
    /v1/apps/app/betaGroups) respond 200 "$(jq '{data:.groups}' "$state")" ;;
    /v1/betaTesters)
      update '.tester_reads += 1'
      # Simulate sparse fieldsets: state is absent unless explicitly requested.
      scoped=false; fields=false
      [[ "$url" != *'filter[apps]=app'* ]] || scoped=true
      [[ "$url" != *'fields[betaTesters]='*state* ]] || fields=true
      respond 200 "$(jq --argjson scoped "$scoped" --argjson fields "$fields" '
        . as $s | [.testers[] | select((.attributes.email | ascii_downcase) == "pedro@pepicrft.me")
          | select(($scoped | not) or ($s.tester_apps[.id] // "app") == "app")
          | if $fields then . else del(.attributes.state) end] |
        if $s.tester_reads > 1 then
          if $s.readback == "missing" then []
          elif $s.readback == "changed-id" then .[0].id = "replacement"
          elif $s.readback == "changed-email" then .[0].attributes.email = "other@example.invalid"
          elif $s.readback == "duplicate" then . + [.[0] | .id = "duplicate"]
          else . end
        else . end | {data:.}' "$state")" ;;
    /v1/users)
      [[ $(jq -r '.denied_users' "$state") != true ]] || respond 403 '{"errors":[{"detail":"private-response-secret"}]}'
      respond 200 "$(jq '{data:.users}' "$state")" ;;
    /v1/users/*/visibleApps) respond 200 "$(jq '{data:.visible}' "$state")" ;;
    /v1/betaGroups/*/relationships/*)
      identifier=${path#/v1/betaGroups/}; identifier=${identifier%%/*}; relationship=${path##*/}
      respond 200 "$(jq --arg id "$identifier" --arg rel "$relationship" '{data:[.memberships[$id][$rel][] | {id:.,type:$rel}]}' "$state")" ;;
    /v1/builds/*/buildBetaDetail) respond 200 "$(jq '{data:.detail}' "$state")" ;;
    /v1/betaGroups/*)
      identifier=${path##*/}
      respond 200 "$(jq --arg id "$identifier" '. as $s | {data:(.groups[] | select(.id == $id) |
        if $s.group_readback_changed then .attributes.isInternalGroup = (.attributes.isInternalGroup | not) else . end)}' "$state")" ;;
    /v1/betaTesters/*)
      identifier=${path##*/}
      respond 200 "$(jq --arg id "$identifier" '{data:(.testers[] | select(.id == $id) | .attributes.state = null)}' "$state")" ;;
    *) fail_fixture "unexpected GET $path" ;;
  esac
fi

[[ -n "$payload" ]] || fail_fixture 'missing write payload'
if [[ "$payload" == @* ]]; then payload=$(cat "${payload#@}"); fi
update --arg method "$method" --arg path "$path" --argjson payload "$payload" \
  '.writes += [{method:$method,path:$path,payload:$payload}]'
response='{}'
case "$method:$path" in
  POST:/v1/betaGroups)
    identifier="group-$(jq '.groups | length' "$state")"
    response=$(jq -n --arg id "$identifier" --argjson payload "$payload" '{data:($payload.data | {type,id:$id,attributes})}')
    update --arg id "$identifier" --argjson row "$(jq '.data' <<< "$response")" \
      '.groups += [$row] | .memberships[$id] = {betaTesters:[],builds:[]}' ;;
  POST:/v1/betaTesters)
    response=$(jq -n --argjson payload "$payload" '{data:($payload.data | {type,id:"tester",attributes:(.attributes + {state:"INVITED"})})}')
    group=$(jq -r '.data.relationships.betaGroups.data[0].id' <<< "$payload")
    update --arg group "$group" --argjson row "$(jq '.data' <<< "$response")" \
      '.testers += [$row] | .memberships[$group].betaTesters += ["tester"]' ;;
  PATCH:/v1/buildBetaDetails/detail)
    update --argjson payload "$payload" '.detail.attributes += $payload.data.attributes' ;;
  POST:/v1/betaGroups/*/relationships/*)
    identifier=${path#/v1/betaGroups/}; identifier=${identifier%%/*}; relationship=${path##*/}
    if [[ $(jq -r '.ignore_build_relationship' "$state") != true || "$relationship" != builds ]]; then
      update --arg id "$identifier" --arg rel "$relationship" --argjson payload "$payload" \
        '.memberships[$id][$rel] += [$payload.data[].id]'
    fi ;;
  *) fail_fixture "unexpected write $method $path" ;;
esac

# Apply the write, then lose its response. A later invocation must reconcile it.
if [[ $(jq -r '.lose_response // empty' "$state") == "$path" ]]; then
  update '.lose_response = null'
  printf '%s\n' 'private-transport-secret' >&2
  exit 52
fi
respond 200 "$response"
