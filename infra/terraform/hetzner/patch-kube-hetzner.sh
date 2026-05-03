#!/usr/bin/env bash

set -euo pipefail

MODULE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.terraform/modules/kube_hetzner/control_planes.tf"

if [[ ! -f "$MODULE_FILE" ]]; then
  echo "kube-hetzner module not found at $MODULE_FILE"
  echo "Run 'mise exec -- terraform init -upgrade' first."
  exit 1
fi

if ! grep -q 'protocol = "https"' "$MODULE_FILE"; then
  echo "kube-hetzner control-plane LB patch already applied."
  exit 0
fi

perl -0pi -e 's/\n\s*health_check \{\n\s*protocol = "https"\n\s*port     = 6443\n\s*interval = tonumber\(trimsuffix\(var\.load_balancer_health_check_interval, "s"\)\)\n\s*timeout  = tonumber\(trimsuffix\(var\.load_balancer_health_check_timeout, "s"\)\)\n\s*retries  = var\.load_balancer_health_check_retries\n\n\s*http \{\n\s*path         = "\/readyz"\n\s*tls          = false\n\s*status_codes = \["200", "401"\]\n\s*\}\n\s*\}\n/\n/s' "$MODULE_FILE"

if grep -q 'protocol = "https"' "$MODULE_FILE"; then
  echo "Failed to patch kube-hetzner control-plane LB health check."
  exit 1
fi

echo "Patched kube-hetzner control-plane LB health check to use the default TCP check."
