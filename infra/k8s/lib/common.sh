#!/usr/bin/env bash

# Shared helpers for the infra/k8s operational scripts. Source this file from a
# script; do not execute it directly.

# Fail early if any required command is missing from PATH.
require_commands() {
  local command_name
  for command_name in "$@"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
      echo "Missing required command: $command_name" >&2
      exit 1
    fi
  done
}

# Print the decoded value of a single field from a Kubernetes secret.
read_kubernetes_secret() {
  local namespace="$1"
  local secret_name="$2"
  local field="$3"

  kubectl -n "$namespace" get secret "$secret_name" \
    -o "jsonpath={.data.${field}}" | base64 --decode
}
