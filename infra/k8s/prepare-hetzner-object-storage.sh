#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  prepare-hetzner-object-storage.sh <target>

Targets:
  production-app
  production-releases
  observability

The current Kubernetes context must point at the target workload cluster. The
script reads the projected destination credentials without printing them,
creates any missing Falkenstein buckets, and applies their access policies.
EOF
}

target="${1:-}"

case "$target" in
  production-app)
    credential_namespace=glossia
    credential_secret=glossia-object-storage
    access_key_field=ACCESS_KEY_ID
    secret_key_field=SECRET_ACCESS_KEY
    bucket_names=(glossia-ai-production)
    visibility=private
    ;;
  production-releases)
    credential_namespace=platform
    credential_secret=glossia-releases-object-storage
    access_key_field=AWS_ACCESS_KEY_ID
    secret_key_field=AWS_SECRET_ACCESS_KEY
    bucket_names=(glossia-ai-releases)
    visibility=public
    ;;
  observability)
    credential_namespace=observability
    credential_secret=glossia-observability-object-storage
    access_key_field=AccessKey
    secret_key_field=SecretKey
    bucket_names=(glossia-ai-mimir glossia-ai-loki glossia-ai-tempo)
    visibility=private
    ;;
  *)
    usage
    exit 1
    ;;
esac

# shellcheck source=./lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

require_commands aws kubectl jq base64

access_key_id="$(
  read_kubernetes_secret \
    "$credential_namespace" \
    "$credential_secret" \
    "$access_key_field"
)"
secret_access_key="$(
  read_kubernetes_secret \
    "$credential_namespace" \
    "$credential_secret" \
    "$secret_key_field"
)"
export AWS_ACCESS_KEY_ID="$access_key_id"
export AWS_SECRET_ACCESS_KEY="$secret_access_key"
export AWS_DEFAULT_REGION=fsn1
export AWS_PAGER=""

cleanup() {
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_DEFAULT_REGION
  unset AWS_PAGER
  unset access_key_id
  unset secret_access_key
}

trap cleanup EXIT INT TERM

endpoint=https://fsn1.your-objectstorage.com
aws_command=(aws --endpoint-url "$endpoint" --region fsn1)

create_bucket() {
  local bucket_name="$1"

  if "${aws_command[@]}" s3api head-bucket --bucket "$bucket_name" \
    >/dev/null 2>&1; then
    echo "Bucket already exists and is accessible: $bucket_name"
    return
  fi

  local create_options=(
    s3api create-bucket
    --bucket "$bucket_name"
    --create-bucket-configuration LocationConstraint=fsn1
  )

  if [[ "$visibility" == "public" ]]; then
    create_options+=(--acl public-read)
  fi

  "${aws_command[@]}" "${create_options[@]}" >/dev/null
  echo "Created bucket: $bucket_name ($visibility)"
}

bucket_owner_id() {
  local bucket_name="$1"

  "${aws_command[@]}" s3api get-bucket-acl \
    --bucket "$bucket_name" \
    --output json \
    | jq -r '.Owner.ID'
}

private_policy() {
  local bucket_name="$1"
  local principal="$2"

  jq -nc \
    --arg bucket_name "$bucket_name" \
    --arg principal "$principal" \
    '{
      Version: "2012-10-17",
      Statement: [
        {
          Sid: "DenyAllUsersButThisKey",
          Effect: "Deny",
          Action: "s3:*",
          Resource: [
            "arn:aws:s3:::\($bucket_name)",
            "arn:aws:s3:::\($bucket_name)/*"
          ],
          NotPrincipal: {
            AWS: $principal
          }
        }
      ]
    }'
}

public_release_policy() {
  local bucket_name="$1"
  local principal="$2"

  jq -nc \
    --arg bucket_name "$bucket_name" \
    --arg principal "$principal" \
    '{
      Version: "2012-10-17",
      Statement: [
        {
          Sid: "AllowPublicObjectDownloads",
          Effect: "Allow",
          Principal: "*",
          Action: ["s3:GetObject", "s3:GetObjectVersion"],
          Resource: "arn:aws:s3:::\($bucket_name)/*"
        },
        {
          Sid: "DenyNonPublicActionsForOtherKeys",
          Effect: "Deny",
          NotAction: ["s3:GetObject", "s3:GetObjectVersion"],
          Resource: [
            "arn:aws:s3:::\($bucket_name)",
            "arn:aws:s3:::\($bucket_name)/*"
          ],
          NotPrincipal: {
            AWS: $principal
          }
        }
      ]
    }'
}

apply_policy() {
  local bucket_name="$1"
  local owner_id
  local principal
  local policy

  owner_id="$(bucket_owner_id "$bucket_name")"
  if [[ ! "$owner_id" =~ ^p[0-9]+$ ]]; then
    echo "Unexpected Hetzner bucket owner identifier for $bucket_name." >&2
    exit 1
  fi

  principal="arn:aws:iam:::user/${owner_id}:${AWS_ACCESS_KEY_ID}"

  if [[ "$visibility" == "public" ]]; then
    policy="$(public_release_policy "$bucket_name" "$principal")"
  else
    policy="$(private_policy "$bucket_name" "$principal")"
  fi

  "${aws_command[@]}" s3api put-bucket-policy \
    --bucket "$bucket_name" \
    --policy "$policy"

  "${aws_command[@]}" s3api get-bucket-policy \
    --bucket "$bucket_name" \
    --query Policy \
    --output text \
    | jq -e --arg visibility "$visibility" '
        any(.Statement[]; .Sid == "DenyAllUsersButThisKey")
        or (
          $visibility == "public"
          and any(.Statement[]; .Sid == "AllowPublicObjectDownloads")
          and any(.Statement[]; .Sid == "DenyNonPublicActionsForOtherKeys")
        )
      ' >/dev/null

  echo "Applied and verified policy: $bucket_name"
}

for bucket_name in "${bucket_names[@]}"; do
  create_bucket "$bucket_name"
  apply_policy "$bucket_name"
done
