#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VARIABLES_FILE="${SCRIPT_DIR}/variables.sh"

# Source saved variables if not already in the environment
if [[ -z "${VPC_ID:-}" ]] && [[ -f "$VARIABLES_FILE" ]]; then
  echo "==> Sourcing variables from ${VARIABLES_FILE}"
  # shellcheck source=/dev/null
  source "$VARIABLES_FILE"
fi

# Verify required variables are set
for var in INSTANCE_ID SG_ID IGW_ID VPC_ID SUBNET_ID; do
  if [[ -z "${!var:-}" ]]; then
    echo "ERROR: ${var} is not set. Cannot tear down." >&2
    echo "       Run: source ${VARIABLES_FILE}" >&2
    exit 1
  fi
done

# Best-effort teardown: attempt every deletion and report failures at the end.
# Orphaned AWS resources cost money, so we must not abort on the first error.
FAILURES=()

echo "==> Terminating instance ${INSTANCE_ID}"
if ! aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"; then
  FAILURES+=("terminate instance ${INSTANCE_ID}")
  echo "WARNING: Failed to terminate instance. Continuing teardown..." >&2
else
  echo "    Waiting for instance to terminate..."
  if ! aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID"; then
    FAILURES+=("wait for instance ${INSTANCE_ID} termination")
    echo "WARNING: Timed out waiting for instance termination. Continuing teardown..." >&2
  fi
fi

echo "==> Deleting security group ${SG_ID}"
if ! aws ec2 delete-security-group --group-id "$SG_ID"; then
  FAILURES+=("delete security group ${SG_ID}")
  echo "WARNING: Failed to delete security group (may still have dependencies)." >&2
fi

echo "==> Detaching and deleting internet gateway ${IGW_ID}"
if ! aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"; then
  FAILURES+=("detach internet gateway ${IGW_ID}")
  echo "WARNING: Failed to detach internet gateway." >&2
fi
if ! aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID"; then
  FAILURES+=("delete internet gateway ${IGW_ID}")
  echo "WARNING: Failed to delete internet gateway." >&2
fi

echo "==> Deleting subnet ${SUBNET_ID}"
if ! aws ec2 delete-subnet --subnet-id "$SUBNET_ID"; then
  FAILURES+=("delete subnet ${SUBNET_ID}")
  echo "WARNING: Failed to delete subnet." >&2
fi

echo "==> Deleting VPC ${VPC_ID} (also removes route table)"
if ! aws ec2 delete-vpc --vpc-id "$VPC_ID"; then
  FAILURES+=("delete VPC ${VPC_ID}")
  echo "WARNING: Failed to delete VPC." >&2
fi

echo "==> Deleting key pair"
aws ec2 delete-key-pair --key-name ederaon-key 2>/dev/null || true
rm -f "${SCRIPT_DIR}/ederaon-key.pem"

echo "==> Removing connect.sh"
rm -f "$(cd "${SCRIPT_DIR}/../.." && pwd)/connect.sh"

echo "==> Removing variables.sh"
rm -f "${VARIABLES_FILE}"

if [[ ${#FAILURES[@]} -gt 0 ]]; then
  echo "" >&2
  echo "WARNING: Teardown completed with ${#FAILURES[@]} error(s):" >&2
  for f in "${FAILURES[@]}"; do
    echo "  - Failed to ${f}" >&2
  done
  echo "" >&2
  echo "  These resources may still exist and incur charges." >&2
  echo "  Check the AWS console and delete them manually." >&2
  exit 1
fi

echo ""
echo "==> Teardown complete!"
echo "    Remember to deactivate your license at on.edera.dev"
