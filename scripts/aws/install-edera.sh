#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VARIABLES_FILE="${SCRIPT_DIR}/variables.sh"

INSTALLER_IMAGE="images.edera.dev/installer:on-preview@sha256:3df0db864e775207ee62f0df4fbadf457e77cf0b739987fa97ff27bbd2b6f437"

# --- Validate prerequisites ---

if [[ -z "${EDERA_LICENSE_KEY:-}" ]]; then
  echo "ERROR: EDERA_LICENSE_KEY is not set." >&2
  echo "       Get your key from https://on.edera.dev and run:" >&2
  echo "       export EDERA_LICENSE_KEY=\"<your-license-key>\"" >&2
  exit 1
fi

# Source saved variables if not already in the environment
if [[ -z "${PUBLIC_IP:-}" ]] && [[ -f "$VARIABLES_FILE" ]]; then
  echo "==> Sourcing variables from ${VARIABLES_FILE}"
  # shellcheck source=/dev/null
  source "$VARIABLES_FILE"
fi

if [[ -z "${PUBLIC_IP:-}" ]]; then
  echo "ERROR: PUBLIC_IP is not set. Has startup.sh been run?" >&2
  exit 1
fi

SSH_KEY="${SCRIPT_DIR}/ederaon-key.pem"
if [[ ! -f "$SSH_KEY" ]]; then
  echo "ERROR: SSH key not found at ${SSH_KEY}" >&2
  exit 1
fi

SSH_OPTS=(-i "${SSH_KEY}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5)

# --- Step 1: Pre-flight check ---

echo "==> Running Edera pre-flight check..."
set +e
preflight_output=$(ssh "${SSH_OPTS[@]}" "ubuntu@${PUBLIC_IP}" \
  "docker run --pull always --pid host --privileged ghcr.io/edera-dev/edera-check:stable preinstall" 2>&1)
preflight_exit=$?
set -e

if [[ "$preflight_exit" -ne 0 ]]; then
  if echo "$preflight_output" | grep -qi "already installed"; then
    echo "    Edera is already installed — skipping to postinstall verification"
    ssh "${SSH_OPTS[@]}" "ubuntu@${PUBLIC_IP}" \
      "docker run --pull always --pid host --privileged ghcr.io/edera-dev/edera-check:stable postinstall"
  else
    echo "$preflight_output" >&2
    echo "ERROR: Edera pre-flight check failed." >&2
    echo "       This could indicate:" >&2
    echo "         - SSH connectivity issues (check instance IP and security group)" >&2
    echo "         - Hardware/kernel incompatibility (review pre-flight output above)" >&2
    exit 1
  fi
else
  echo "$preflight_output"
fi

# --- Step 2: Authenticate and install ---

echo "==> Logging into Edera registry..."
if ! printf '%s' "${EDERA_LICENSE_KEY}" | ssh "${SSH_OPTS[@]}" "ubuntu@${PUBLIC_IP}" \
  "docker login -u license --password-stdin images.edera.dev"; then
  echo "ERROR: Docker registry authentication failed." >&2
  echo "       This could indicate:" >&2
  echo "         - Invalid EDERA_LICENSE_KEY (verify at https://on.edera.dev)" >&2
  echo "         - Registry images.edera.dev is unreachable from the instance" >&2
  echo "         - Docker daemon not running (reconnect SSH to pick up docker group)" >&2
  exit 1
fi

echo "==> Pulling installer image..."
if ! ssh "${SSH_OPTS[@]}" "ubuntu@${PUBLIC_IP}" \
  "docker pull ${INSTALLER_IMAGE}"; then
  echo "ERROR: Failed to pull installer image." >&2
  echo "       This could indicate:" >&2
  echo "         - Registry authentication expired (re-run login step)" >&2
  echo "         - Image digest mismatch (check INSTALLER_IMAGE variable)" >&2
  echo "         - Insufficient disk space on the instance" >&2
  exit 1
fi

echo "==> Running installer (instance will reboot)..."
set +e
# Pass the license key via heredoc to avoid exposing it in process arguments.
ssh "${SSH_OPTS[@]}" "ubuntu@${PUBLIC_IP}" bash <<REMOTE_INSTALLER
export EDERA_LICENSE_KEY='${EDERA_LICENSE_KEY//\'/\'\\\'\'}'
docker run --rm --privileged --pid=host --net=host \
  --env 'TARGET_DIR=/host' \
  --env EDERA_LICENSE_KEY \
  --volume '/:/host' \
  ${INSTALLER_IMAGE}
REMOTE_INSTALLER
installer_exit=$?
set -e

if [[ "$installer_exit" -eq 255 ]]; then
  echo "    SSH disconnected (exit 255 — expected if instance is rebooting)"
  echo "    If the wait below times out, check SSH key and security group."
elif [[ "$installer_exit" -ne 0 ]]; then
  echo "ERROR: Installer failed with exit code ${installer_exit}" >&2
  echo "       Check Docker daemon, license key, and image pull access." >&2
  exit 1
fi

# --- Step 3: Wait for reboot and SSH ---

echo "==> Waiting for instance to reboot and SSH to become available..."
echo "    (Xen boot is slower than normal — this may take 2-3 minutes)"
sleep 30

MAX_ATTEMPTS=30
ATTEMPT=0
until ssh "${SSH_OPTS[@]}" "ubuntu@${PUBLIC_IP}" true 2>/dev/null; do
  ATTEMPT=$((ATTEMPT + 1))
  if [[ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ]]; then
    echo "ERROR: SSH not available after ${MAX_ATTEMPTS} attempts." >&2
    echo "       Last SSH error:" >&2
    timeout 10 ssh "${SSH_OPTS[@]}" "ubuntu@${PUBLIC_IP}" true 2>&1 || true
    exit 1
  fi
  echo "    Attempt ${ATTEMPT}/${MAX_ATTEMPTS} — retrying in 10s..."
  sleep 10
done

echo "==> SSH is back. Verifying Edera kernel..."
set +e
KERNEL_VERSION=$(ssh "${SSH_OPTS[@]}" "ubuntu@${PUBLIC_IP}" "uname -r")
ssh_exit=$?
set -e

if [[ "$ssh_exit" -ne 0 ]]; then
  echo "ERROR: Failed to verify kernel version (SSH exit code: ${ssh_exit})" >&2
  echo "       The instance may not have started correctly after reboot." >&2
  echo "       Try connecting manually: ssh ${SSH_OPTS} ubuntu@${PUBLIC_IP}" >&2
  exit 1
fi
echo "    Kernel: ${KERNEL_VERSION}"

if [[ "${KERNEL_VERSION}" != *edera* ]]; then
  echo "ERROR: Edera kernel not detected (got: ${KERNEL_VERSION})" >&2
  echo "       The installer may have failed silently. Check instance logs." >&2
  exit 1
fi

# --- Step 4: Wait for protect-daemon to be ready ---

echo "==> Waiting for protect-daemon to become active..."
echo "    (Edera services take time to initialise after Xen boot)"
DAEMON_ATTEMPTS=0
DAEMON_MAX=30
while true; do
  set +e
  DAEMON_STATUS=$(ssh "${SSH_OPTS[@]}" "ubuntu@${PUBLIC_IP}" \
    "sudo systemctl is-active protect-daemon")
  ssh_exit=$?
  set -e

  if [[ "$ssh_exit" -eq 255 ]]; then
    echo "    WARNING: SSH connection failed — instance may still be starting"
  elif [[ "$ssh_exit" -ne 0 ]] && [[ "$ssh_exit" -ne 3 ]]; then
    echo "    WARNING: Unexpected SSH/command error (exit code: ${ssh_exit})"
  fi

  if [[ "${DAEMON_STATUS}" == "active" ]]; then
    echo "    protect-daemon is active"
    break
  fi
  if [[ "${DAEMON_STATUS}" == "failed" ]]; then
    echo "ERROR: protect-daemon entered 'failed' state and will not recover automatically." >&2
    echo "       Check logs: ./connect.sh then 'journalctl -u protect-daemon'" >&2
    exit 1
  fi
  DAEMON_ATTEMPTS=$((DAEMON_ATTEMPTS + 1))
  if [[ "$DAEMON_ATTEMPTS" -ge "$DAEMON_MAX" ]]; then
    echo "ERROR: protect-daemon did not become active after ${DAEMON_MAX} attempts." >&2
    echo "       Last status: ${DAEMON_STATUS:-<empty>}" >&2
    echo "       Check logs: ./connect.sh then 'journalctl -u protect-daemon'" >&2
    exit 1
  fi
  if [[ -z "${DAEMON_STATUS}" ]]; then
    echo "    Attempt ${DAEMON_ATTEMPTS}/${DAEMON_MAX} — no response (SSH may still be stabilising), retrying in 10s..."
  else
    echo "    Attempt ${DAEMON_ATTEMPTS}/${DAEMON_MAX} — status: ${DAEMON_STATUS}, retrying in 10s..."
  fi
  sleep 10
done

# --- Step 5: Copy demos and run smoke test ---

echo "==> Copying demos to instance..."
if ! "${SCRIPT_DIR}/copy-demos.sh"; then
  echo "ERROR: Failed to copy demo files to the instance." >&2
  echo "       Check SSH connectivity and disk space on the remote instance." >&2
  exit 1
fi

echo "==> Running DEMO_00 (verification) as smoke test..."
if ! ssh "${SSH_OPTS[@]}" "ubuntu@${PUBLIC_IP}" "bash /home/ubuntu/demos/DEMO_00/test.sh"; then
  echo "ERROR: Smoke test (DEMO_00) failed." >&2
  echo "       The Edera kernel is installed but the demo verification did not pass." >&2
  echo "       Connect manually to investigate: ./connect.sh" >&2
  exit 1
fi

echo ""
echo "==> Edera On installation complete!"
echo "    Connect: ./connect.sh"
echo ""
echo "    To run all demos:"
echo "      ssh into the instance, then: bash /home/ubuntu/demos/run-all.sh"
