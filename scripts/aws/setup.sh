#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VARIABLES_FILE="${SCRIPT_DIR}/variables.sh"

# Print cleanup guidance if the script exits on error (AWS resources may exist).
cleanup_hint() {
  echo "" >&2
  echo "=========================================" >&2
  echo "  Setup FAILED" >&2
  echo "=========================================" >&2
  echo "" >&2
  echo "  AWS resources may have been created." >&2
  echo "  To clean up: ./scripts/aws/teardown.sh" >&2
  echo "" >&2
}
trap cleanup_hint ERR

# --- Validate prerequisites ---

echo "==> Validating prerequisites..."

if [[ -z "${EDERA_LICENSE_KEY:-}" ]]; then
  echo "ERROR: EDERA_LICENSE_KEY is not set." >&2
  echo "       Get your key from https://on.edera.dev and run:" >&2
  echo "       export EDERA_LICENSE_KEY=\"<your-license-key>\"" >&2
  exit 1
fi

if ! aws_output=$(aws sts get-caller-identity 2>&1); then
  echo "ERROR: AWS credentials check failed." >&2
  echo "       ${aws_output}" >&2
  echo "" >&2
  echo "       Common fixes:" >&2
  echo "         SSO:    aws sso login --profile edera" >&2
  echo "         Static: aws configure" >&2
  exit 1
fi

echo "  EDERA_LICENSE_KEY is set"
echo "  AWS credentials are valid"

# --- Phase 1: Provision infrastructure ---

echo ""
echo "=========================================="
echo "  Phase 1: Provisioning AWS infrastructure"
echo "=========================================="
echo ""

"${SCRIPT_DIR}/startup.sh"

# startup.sh runs as a subprocess, so its exports don't propagate here.
# Source variables.sh so PUBLIC_IP is available for the summary below.
# (install-edera.sh sources variables.sh itself as a fallback.)
if [[ ! -f "${VARIABLES_FILE}" ]]; then
  echo "ERROR: ${VARIABLES_FILE} was not created by startup.sh." >&2
  echo "       Check startup.sh output above for errors." >&2
  exit 1
fi
# shellcheck source=/dev/null
source "${VARIABLES_FILE}"

# --- Phase 2: Install Edera ---

echo ""
echo "=========================================="
echo "  Phase 2: Installing Edera"
echo "=========================================="
echo ""

"${SCRIPT_DIR}/install-edera.sh"

# --- Summary ---

echo ""
echo "=========================================="
echo "  Setup Complete!"
echo "=========================================="
echo ""
echo "  Instance: ${PUBLIC_IP}"
echo "  Connect:  ./connect.sh"
echo ""
echo "  To restore variables in a new shell:"
echo "    source scripts/aws/variables.sh"
echo ""
echo "  To tear down all resources:"
echo "    ./scripts/aws/teardown.sh"
