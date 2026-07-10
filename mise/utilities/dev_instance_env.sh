if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  SCRIPT_PATH="${BASH_SOURCE[0]}"
elif [[ -n "${ZSH_VERSION:-}" ]]; then
  SCRIPT_PATH="${(%):-%x}"
else
  SCRIPT_PATH="${0}"
fi

SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ROOT_INSTANCE_FILE="${PROJECT_ROOT}/.glossia-dev-instance"

resolve_git_path() {
  local target_name="$1"
  local fallback_path="$2"
  local git_path=""

  if command -v git >/dev/null 2>&1 && git -C "${PROJECT_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git_path="$(
      git -C "${PROJECT_ROOT}" rev-parse --path-format=absolute --git-path "${target_name}" 2>/dev/null ||
        git -C "${PROJECT_ROOT}" rev-parse --git-path "${target_name}" 2>/dev/null ||
        true
    )"

    if [[ -n "${git_path}" && "${git_path}" != /* ]]; then
      git_path="${PROJECT_ROOT}/${git_path#./}"
    fi
  fi

  if [[ -n "${git_path}" ]]; then
    printf '%s' "${git_path}"
  else
    printf '%s' "${fallback_path}"
  fi
}

INSTANCE_FILE="$(resolve_git_path "glossia-dev-instance" "${ROOT_INSTANCE_FILE}")"

validate_suffix() {
  local suffix="$1"

  [[ "$suffix" =~ ^[0-9]+$ ]] || return 1
  (( suffix >= 1 && suffix <= 999 ))
}

persist_suffix() {
  local suffix="$1"
  local target="$2"

  mkdir -p "$(dirname "${target}")" 2>/dev/null || return 1
  printf '%s' "${suffix}" | tee "${target}" >/dev/null 2>&1
}

collect_used_suffixes() {
  # Suffixes already assigned to the main checkout and every linked worktree, so
  # a freshly generated one can avoid colliding on ports and database names.
  local common_dir="" f
  if command -v git >/dev/null 2>&1 && git -C "${PROJECT_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    common_dir="$(git -C "${PROJECT_ROOT}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
  fi
  [[ -n "${common_dir}" && -d "${common_dir}" ]] || return 0

  for f in "${common_dir}/glossia-dev-instance" "${common_dir}"/worktrees/*/glossia-dev-instance; do
    [[ -s "${f}" ]] || continue
    [[ "${f}" -ef "${INSTANCE_FILE}" ]] 2>/dev/null && continue
    tr -d '[:space:]' < "${f}"
    printf '\n'
  done
}

generate_suffix() {
  # Pick a suffix in [100, 999] not used by any other instance. Seed awk's RNG
  # with the PID so worktrees bootstrapped within the same second diverge instead
  # of sharing awk's default time(0) seed.
  local used
  used="$(collect_used_suffixes | tr '\n' ' ')"
  awk -v used="${used}" -v seed="$$" '
    BEGIN {
      srand(seed)
      n = split(used, list, " ")
      for (i = 1; i <= n; i++) taken[list[i]] = 1
      for (attempt = 0; attempt < 100000; attempt++) {
        candidate = int(100 + rand() * 900)
        if (!(candidate in taken)) { print candidate; exit 0 }
      }
      exit 1
    }
  '
}

ensure_suffix() {
  local suffix=""

  # This instance's own persisted suffix wins over everything else. When a
  # worktree is nested under the main checkout, mise loads both mise.toml files
  # and runs this script once per project root; the parent run exports its own
  # GLOSSIA_DEV_INSTANCE, which would otherwise leak into the worktree. Reading
  # our own file first keeps each worktree on its distinct suffix regardless of
  # what a parent (or stale env) provides.
  if [[ -s "${INSTANCE_FILE}" ]]; then
    suffix="$(tr -d '[:space:]' < "${INSTANCE_FILE}")"
  # No file yet: trust GLOSSIA_DEV_INSTANCE only when it belongs to THIS project
  # root, or when it was set externally with no provenance marker (an explicit
  # override such as CI's GLOSSIA_DEV_INSTANCE=1). A value carrying a different
  # root leaked from a parent checkout and must be ignored.
  elif [[ -n "${GLOSSIA_DEV_INSTANCE:-}" ]] &&
    { [[ "${GLOSSIA_DEV_INSTANCE_ROOT:-}" == "${PROJECT_ROOT}" ]] || [[ -z "${GLOSSIA_DEV_INSTANCE_ROOT:-}" ]]; }; then
    suffix="${GLOSSIA_DEV_INSTANCE}"
  elif [[ -s "${ROOT_INSTANCE_FILE}" ]]; then
    suffix="$(tr -d '[:space:]' < "${ROOT_INSTANCE_FILE}")"
  else
    suffix="$(generate_suffix)"
  fi

  validate_suffix "${suffix}" || {
    echo "Invalid dev instance suffix '${suffix}'. Expected an integer between 1 and 999." >&2
    return 1
  }

  if ! persist_suffix "${suffix}" "${INSTANCE_FILE}"; then
    if [[ "${INSTANCE_FILE}" != "${ROOT_INSTANCE_FILE}" ]] &&
      persist_suffix "${suffix}" "${ROOT_INSTANCE_FILE}"; then
      INSTANCE_FILE="${ROOT_INSTANCE_FILE}"
    else
      echo "Failed to persist dev instance suffix '${suffix}'." >&2
      return 1
    fi
  fi

  printf '%s' "${suffix}"
}

suffix="$(ensure_suffix)"
test_partition="${MIX_TEST_PARTITION:-}"

export GLOSSIA_DEV_INSTANCE="${suffix}"
export GLOSSIA_DEV_INSTANCE_ROOT="${PROJECT_ROOT}"

# App ports (scoped per clone)
export GLOSSIA_SERVER_PORT="$((4050 + suffix))"
export GLOSSIA_SERVER_URL="http://localhost:${GLOSSIA_SERVER_PORT}"
export GLOSSIA_TEST_PORT="$((4002 + suffix))"

# Database names (scoped per clone; infrastructure ports are shared)
export GLOSSIA_POSTGRES_DB="glossia_dev_${suffix}"
export GLOSSIA_CLICKHOUSE_DB="glossia_dev_${suffix}"
export GLOSSIA_TEST_POSTGRES_DB="glossia_test${test_partition}_${suffix}"
export GLOSSIA_TEST_CLICKHOUSE_DB="glossia_test${test_partition}_${suffix}"
