#!/bin/bash
set -euo pipefail

if [[ "$(id -u)" != 0 ]]; then
  echo 'The benchmark guest launcher requires root for a private network namespace.' >&2
  exit 1
fi

mkdir -p /tmp/glossia
# Serialize launch attempts; the driver intentionally remains running on resume.
exec 9>/tmp/glossia/launch.lock
flock -x -w 10 9
if [[ -f /tmp/glossia/driver.pid ]]; then
  read -r driver_pid < /tmp/glossia/driver.pid
  if [[ "$driver_pid" =~ ^[1-9][0-9]*$ ]] && kill -0 "$driver_pid" 2>/dev/null; then
    echo 'Preview driver is already alive; refusing to restart it.' >&2
    exit 1
  fi
fi

test -r /opt/glossia-bench/preview-runtime.mjs
test -r /opt/glossia-bench/preview-launch.json
test -d /tmp/glossia/repo

# All inherited execd stdio and the launch lock are closed in the background
# child. Only network isolation changes: execd remains in its original namespace.
unshare --net --fork /bin/bash -c '
  set -euo pipefail
  ip link set lo up
  cd /tmp/glossia/repo
  printf "%s\n" "$$" > /tmp/glossia/driver.pid
  exec node /opt/glossia-bench/preview-runtime.mjs /opt/glossia-bench/preview-launch.json
' </dev/null >/tmp/glossia/preview-runtime.log 2>&1 9>&- &
launcher_pid=$!

# Bound startup acknowledgement, not app readiness. The runner waits for a
# verified frame separately. Do not silently restart a failed driver.
for ((attempt = 0; attempt < 100; attempt++)); do
  if ! kill -0 "$launcher_pid" 2>/dev/null; then
    echo 'Preview namespace launcher exited; inspect preview-runtime.log.' >&2
    exit 1
  fi
  if [[ -f /tmp/glossia/driver.pid ]]; then
    read -r driver_pid < /tmp/glossia/driver.pid
    if [[ "$driver_pid" =~ ^[1-9][0-9]*$ ]] && kill -0 "$driver_pid" 2>/dev/null \
      && [[ "$(readlink "/proc/$driver_pid/exe" 2>/dev/null || true)" == */node ]]; then
      printf '{"driver_pid":%s}\n' "$driver_pid"
      exit 0
    fi
  fi
  sleep 0.05
done
echo 'Timed out waiting for the Node driver PID.' >&2
exit 1
