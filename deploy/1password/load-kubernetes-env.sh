#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
env_template="${script_dir}/kubernetes-production.env.tpl"
github_env=""

required_vars=(
  POSTGRES_PASSWORD
  SECRET_KEY_BASE
  METRICS_BEARER_TOKEN
  OPS_AUTH_PASSWORD
  SMTP_HOST
  SMTP_PORT
  SMTP_USERNAME
  SMTP_PASSWORD
  GF_SECURITY_ADMIN_PASSWORD
)

usage() {
  cat <<'EOF'
Usage:
  load-kubernetes-env.sh [--github-env PATH] [--require NAME ...] [--] [command ...]

Examples:
  ./deploy/1password/load-kubernetes-env.sh -- ./deploy/k8s/render-secrets.sh
  ./deploy/1password/load-kubernetes-env.sh --github-env "$GITHUB_ENV" --require K8S_KUBECONFIG_B64
EOF
}

contains_required_var() {
  local candidate="$1"
  local name

  for name in "${required_vars[@]}"; do
    if [[ "${name}" == "${candidate}" ]]; then
      return 0
    fi
  done

  return 1
}

emit_env() {
  local key="$1"
  local value="$2"

  if [[ -n "${github_env}" ]]; then
    local delimiter="OP_ENV_${key}_$$"
    {
      printf '%s<<%s\n' "${key}" "${delimiter}"
      printf '%s\n' "${value}"
      printf '%s\n' "${delimiter}"
    } >> "${github_env}"
  else
    export "${key}=${value}"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --github-env)
      github_env="$2"
      shift 2
      ;;
    --require)
      required_vars+=("$2")
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

if [[ ! -f "${env_template}" ]]; then
  echo "1Password env template not found at ${env_template}" >&2
  exit 1
fi

while IFS='=' read -r key ref; do
  [[ -z "${key}" ]] && continue
  [[ "${key}" =~ ^# ]] && continue
  [[ -z "${ref}" ]] && continue

  if contains_required_var "${key}"; then
    value="$(op read "${ref}")"
    emit_env "${key}" "${value}"
    continue
  fi

  if value="$(op read "${ref}" 2>/dev/null)"; then
    emit_env "${key}" "${value}"
  fi
done < "${env_template}"

if [[ -n "${github_env}" ]]; then
  exit 0
fi

if [[ $# -eq 0 ]]; then
  usage
  exit 0
fi

exec "$@"
