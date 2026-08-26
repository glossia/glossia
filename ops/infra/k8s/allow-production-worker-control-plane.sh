#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  allow-production-worker-control-plane.sh [once|watch]

Adds a narrow port 6443 firewall rule for every production worker server
that is not already allowed to reach the Kubernetes control plane. The script
never removes a rule. Run it in watch mode during worker replacement, then stop
it after every replacement node is Ready.

HCLOUD_TOKEN must contain a token for the production Hetzner project.
EOF
}

mode="${1:-once}"
case "$mode" in
  once|watch)
    ;;
  *)
    usage
    exit 1
    ;;
esac

if [[ -z "${HCLOUD_TOKEN:-}" ]]; then
  echo "HCLOUD_TOKEN is required." >&2
  exit 1
fi

for command_name in hcloud jq; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name" >&2
    exit 1
  fi
done

firewall_name="${HCLOUD_FIREWALL_NAME:-glossia-production-control-plane-api}"
server_prefix="${HCLOUD_SERVER_PREFIX:-glossia-production-}"
poll_interval_seconds="${POLL_INTERVAL_SECONDS:-5}"

reconcile() {
  local firewall_json
  local server_json

  firewall_json="$(hcloud firewall describe "$firewall_name" -o json)"
  server_json="$(hcloud server list -o json)"

  while IFS= read -r worker_address; do
    [[ -n "$worker_address" ]] || continue

    local worker_network="${worker_address}/32"
    if jq -e \
      --arg worker_network "$worker_network" \
      'def allows_port($wanted):
        if . == null then
          true
        elif test("^[0-9]+$") then
          tonumber == $wanted
        elif test("^[0-9]+-[0-9]+$") then
          split("-") | (.[0] | tonumber) <= $wanted and (.[1] | tonumber) >= $wanted
        else
          false
        end;

      .rules[]
        | select(
            .direction == "in"
            and .protocol == "tcp"
            and (.port | allows_port(6443))
          )
        | (.source_ips // [])[]
        | select(. == $worker_network)' \
      >/dev/null <<<"$firewall_json"; then
      echo "Already allowed: $worker_network"
      continue
    fi

    echo "Allowing worker: $worker_network"
    hcloud firewall add-rule "$firewall_name" \
      --direction in \
      --protocol tcp \
      --port 6443 \
      --source-ips "$worker_network" \
      --description "Kubernetes worker control plane"

    firewall_json="$(hcloud firewall describe "$firewall_name" -o json)"
  done < <(
    jq -r \
      --arg server_prefix "$server_prefix" \
      '.[]
        | select(.name | startswith($server_prefix))
        | select(.labels.machine_type == "worker")
        | .public_net.ipv4.ip // empty' \
      <<<"$server_json" \
      | sort -u
  )
}

reconcile

if [[ "$mode" == "watch" ]]; then
  while true; do
    sleep "$poll_interval_seconds"
    reconcile
  done
fi
