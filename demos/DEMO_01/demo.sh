#!/usr/bin/env bash
# Note: set -euo pipefail is intentionally omitted — demo-magic manages
# execution flow and uses eval, which is incompatible with errexit.

########################
# Demo 01: Container Escape vs Zone Isolation
#
# Scripted demo for video recording using demo-magic.
# Press ENTER to advance between steps.
#
# Prerequisites:
#   - pv installed (apt-get install pv / brew install pv)
#   - Docker installed and running
#   - Edera On installed and instance rebooted
#
# Usage:
#   ./demo.sh        # interactive (press ENTER to advance)
#   ./demo.sh -n     # non-interactive (auto-advance)
#   ./demo.sh -d     # disable simulated typing (instant output)
########################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEMO_MAGIC="${SCRIPT_DIR}/../demo-magic.sh"
if [ ! -f "${DEMO_MAGIC}" ]; then
  echo "ERROR: demo-magic.sh not found at ${DEMO_MAGIC}" >&2
  exit 1
fi
source "${DEMO_MAGIC}"

# Override defaults after source (colors are now defined; respects -d flag)
[[ -n "${TYPE_SPEED+x}" ]] && TYPE_SPEED=40
DEMO_PROMPT="${GREEN}edera-on ${CYAN}\$ ${COLOR_RESET}"

clear

p "# Demo 01: Container Escape vs Zone Isolation"
p "# Side-by-side: Docker shared-kernel vs Edera VM isolation"
wait

# ===========================================================
# Part 1: Docker
# ===========================================================
p ""
p "# ═══════════════════════════════════════════"
p "# Part 1: The Problem — What Docker Exposes"
p "# ═══════════════════════════════════════════"
wait

# -----------------------------------------------------------
p ""
p "# Host process visibility"
p "# --pid=host shares the host PID namespace with the container"
pe "docker run --rm --pid=host alpine ps aux | head -20"
wait

# -----------------------------------------------------------
p ""
p "# Privileged device access"
p "# --privileged gives the container access to every host device"
pe "docker run --rm --privileged alpine ls /dev | wc -l"
wait

# -----------------------------------------------------------
p ""
p "# Shared kernel"
p "# Every Docker container runs the same kernel as the host"
pe "docker run --rm alpine uname -r"
wait

# -----------------------------------------------------------
p ""
p "# Host filesystem traversal"
p "# With --pid=host, /proc/1/root reaches the host filesystem"
pe "docker run --rm --pid=host --privileged alpine cat /proc/1/root/etc/hostname"
wait

# ===========================================================
# Part 2: Edera Zones
# ===========================================================
p ""
p "# ═══════════════════════════════════════════"
p "# Part 2: The Fix — Same Workloads in Edera Zones"
p "# ═══════════════════════════════════════════"
wait

# -----------------------------------------------------------
p ""
p "# Launch two isolated zones"
pe "sudo protect zone launch -n zone-a --wait"
pe "sudo protect zone launch -n zone-b --wait"
wait

# -----------------------------------------------------------
p ""
p "# Check 1: Kernel isolation"
p "# Each zone runs its OWN kernel inside a Xen VM"
p "# Host kernel:"
pe "uname -r"
pe "sudo protect workload launch --zone zone-a --name kernel-check -t -a docker.io/library/alpine:latest uname -r"
wait

# -----------------------------------------------------------
p ""
p "# Check 2: Process isolation"
p "# Launch a workload in zone-a, then try to see it from zone-b"
pe "sudo protect workload launch --zone zone-a --name secret-app docker.io/library/alpine:latest sleep 3600"
p "# Zone-b cannot see zone-a's processes"
pe "sudo protect workload launch --zone zone-b --name spy -t -a docker.io/library/alpine:latest ps aux"
wait

# -----------------------------------------------------------
p ""
p "# Check 3: Filesystem isolation"
p "# The zone sees its own hostname, not the host's"
pe "sudo protect workload launch --zone zone-a --name fs-check -t -a docker.io/library/alpine:latest cat /etc/hostname"
wait

# -----------------------------------------------------------
p ""
p "# Check 4: Device isolation"
p "# The zone only sees virtualised devices, not host hardware"
pe "sudo protect workload launch --zone zone-a --name dev-check -t -a docker.io/library/alpine:latest ls /dev"
wait

# ===========================================================
# Part 3: Cleanup
# ===========================================================
p ""
p "# ═══════════════════════════════════════════"
p "# Cleanup"
p "# ═══════════════════════════════════════════"
pe "sudo protect workload destroy secret-app"
pe "sudo protect workload destroy kernel-check"
pe "sudo protect workload destroy spy"
pe "sudo protect workload destroy fs-check"
pe "sudo protect workload destroy dev-check"
pe "sudo protect zone destroy zone-a"
pe "sudo protect zone destroy zone-b"
wait

p ""
p "# Docker exposes the host. Edera isolates workloads."
