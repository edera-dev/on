#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VARIABLES_FILE="${SCRIPT_DIR}/variables.sh"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source saved variables if not already in the environment
if [[ -z "${PUBLIC_IP:-}" ]] && [[ -f "$VARIABLES_FILE" ]]; then
  echo "==> Sourcing variables from ${VARIABLES_FILE}"
  # shellcheck source=/dev/null
  source "$VARIABLES_FILE"
fi

# Validate required variables
if [[ -z "${PUBLIC_IP:-}" ]]; then
  echo "ERROR: PUBLIC_IP is not set. Cannot copy demos." >&2
  echo "       Run: source ${VARIABLES_FILE}" >&2
  exit 1
fi

# Validate key file exists
SSH_KEY="${SCRIPT_DIR}/ederaon-key.pem"
if [[ ! -f "$SSH_KEY" ]]; then
  echo "ERROR: SSH key not found at ${SSH_KEY}" >&2
  echo "       Has the instance been provisioned with startup.sh?" >&2
  exit 1
fi

SSH_OPTS=(-i "${SSH_KEY}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5)

echo "==> Copying demos to ${PUBLIC_IP}:/home/ubuntu/demos/"
rsync -a -e "ssh $(printf '%q ' "${SSH_OPTS[@]}")" "${REPO_ROOT}/demos/" "ubuntu@${PUBLIC_IP}:/home/ubuntu/demos/"

echo ""
echo "==> Demos copied successfully!"
echo "    Remote path: /home/ubuntu/demos/"
