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

# If variables are still missing, discover resources by AWS tags.
# All resources are tagged ederaon-* during setup, so we can find them
# even when variables.sh is lost or the shell session has changed.
if [[ -z "${VPC_ID:-}" ]]; then
  echo "==> variables.sh not found — discovering resources by AWS tags..."

  # Discover VPCs tagged ederaon-vpc
  mapfile -t VPC_IDS < <(
    aws ec2 describe-vpcs \
      --filters "Name=tag:Name,Values=ederaon-vpc" \
      --query 'Vpcs[].VpcId' --output text | tr '\t' '\n'
  )

  if [[ ${#VPC_IDS[@]} -eq 0 || "${VPC_IDS[0]}" == "None" || -z "${VPC_IDS[0]}" ]]; then
    echo "No ederaon resources found in AWS. Nothing to tear down."
    exit 0
  fi

  echo "    Found ${#VPC_IDS[@]} ederaon VPC(s): ${VPC_IDS[*]}"

  # Discover instances by key-name (all ederaon instances use ederaon-key)
  mapfile -t INSTANCE_IDS < <(
    aws ec2 describe-instances \
      --filters "Name=key-name,Values=ederaon-key" \
                "Name=instance-state-name,Values=pending,running,stopping,stopped" \
      --query 'Reservations[].Instances[].InstanceId' --output text | tr '\t' '\n'
  )

  # Collect networking resources from all discovered VPCs
  ALL_SG_IDS=()
  ALL_IGW_IDS=()
  ALL_SUBNET_IDS=()

  for vpc in "${VPC_IDS[@]}"; do
    # Security groups (exclude the default SG which can't be deleted)
    mapfile -t sgs < <(
      aws ec2 describe-security-groups \
        --filters "Name=vpc-id,Values=${vpc}" "Name=group-name,Values=ederaon-sg" \
        --query 'SecurityGroups[].GroupId' --output text | tr '\t' '\n'
    )
    ALL_SG_IDS+=("${sgs[@]}")

    # Internet gateways
    mapfile -t igws < <(
      aws ec2 describe-internet-gateways \
        --filters "Name=attachment.vpc-id,Values=${vpc}" \
        --query 'InternetGateways[].InternetGatewayId' --output text | tr '\t' '\n'
    )
    ALL_IGW_IDS+=("${igws[@]}")

    # Subnets
    mapfile -t subnets < <(
      aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=${vpc}" \
        --query 'Subnets[].SubnetId' --output text | tr '\t' '\n'
    )
    ALL_SUBNET_IDS+=("${subnets[@]}")
  done
fi

# Best-effort teardown: attempt every deletion and report failures at the end.
# Orphaned AWS resources cost money, so we must not abort on the first error.
FAILURES=()

# Build resource lists — either from variables.sh (single stack) or discovery (multi-stack)
if [[ -z "${ALL_SG_IDS+x}" ]]; then
  # Single-stack path: variables were sourced
  INSTANCE_IDS=("$INSTANCE_ID")
  ALL_SG_IDS=("$SG_ID")
  ALL_IGW_IDS=("$IGW_ID")
  ALL_SUBNET_IDS=("$SUBNET_ID")
  VPC_IDS=("$VPC_ID")
fi

# --- Terminate instances ---
if [[ ${#INSTANCE_IDS[@]} -gt 0 && -n "${INSTANCE_IDS[0]}" ]]; then
  echo "==> Terminating ${#INSTANCE_IDS[@]} instance(s): ${INSTANCE_IDS[*]}"
  if ! aws ec2 terminate-instances --instance-ids "${INSTANCE_IDS[@]}"; then
    FAILURES+=("terminate instances ${INSTANCE_IDS[*]}")
    echo "WARNING: Failed to terminate instances. Continuing teardown..." >&2
  else
    echo "    Waiting for instances to terminate..."
    if ! aws ec2 wait instance-terminated --instance-ids "${INSTANCE_IDS[@]}"; then
      FAILURES+=("wait for instance termination")
      echo "WARNING: Timed out waiting for instance termination. Continuing teardown..." >&2
    fi
  fi
fi

# --- Delete security groups ---
for sg in "${ALL_SG_IDS[@]}"; do
  [[ -z "$sg" || "$sg" == "None" ]] && continue
  echo "==> Deleting security group ${sg}"
  if ! aws ec2 delete-security-group --group-id "$sg"; then
    FAILURES+=("delete security group ${sg}")
    echo "WARNING: Failed to delete security group (may still have dependencies)." >&2
  fi
done

# --- Detach and delete internet gateways ---
for i in "${!ALL_IGW_IDS[@]}"; do
  igw="${ALL_IGW_IDS[$i]}"
  vpc="${VPC_IDS[$i]}"
  [[ -z "$igw" || "$igw" == "None" ]] && continue
  echo "==> Detaching and deleting internet gateway ${igw}"
  if ! aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc"; then
    FAILURES+=("detach internet gateway ${igw}")
    echo "WARNING: Failed to detach internet gateway." >&2
  fi
  if ! aws ec2 delete-internet-gateway --internet-gateway-id "$igw"; then
    FAILURES+=("delete internet gateway ${igw}")
    echo "WARNING: Failed to delete internet gateway." >&2
  fi
done

# --- Delete subnets ---
for subnet in "${ALL_SUBNET_IDS[@]}"; do
  [[ -z "$subnet" || "$subnet" == "None" ]] && continue
  echo "==> Deleting subnet ${subnet}"
  if ! aws ec2 delete-subnet --subnet-id "$subnet"; then
    FAILURES+=("delete subnet ${subnet}")
    echo "WARNING: Failed to delete subnet." >&2
  fi
done

# --- Delete VPCs ---
for vpc in "${VPC_IDS[@]}"; do
  [[ -z "$vpc" || "$vpc" == "None" ]] && continue
  echo "==> Deleting VPC ${vpc} (also removes route table)"
  if ! aws ec2 delete-vpc --vpc-id "$vpc"; then
    FAILURES+=("delete VPC ${vpc}")
    echo "WARNING: Failed to delete VPC." >&2
  fi
done

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
