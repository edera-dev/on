#!/usr/bin/env bash
# Note: set -euo pipefail is intentionally omitted — demo-magic manages
# execution flow and uses eval, which is incompatible with errexit.

########################
# Demo 00: Verify Edera On
#
# Scripted demo for video recording using demo-magic.
# Press ENTER to advance between steps.
#
# Prerequisites:
#   - pv installed (apt-get install pv / brew install pv)
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

p "# Demo 00: Verify Edera On"
p "# Post-installation health check"
wait

# -----------------------------------------------------------
p "# Check 1: Is the Edera kernel booted?"
p "# Expected: version string containing 'edera'"
pe "uname -r"
wait

# -----------------------------------------------------------
p ""
p "# Check 2: Is the Xen hypervisor active?"
p "# Expected: a directory listing (capabilities, xenbus, ...)"
pe "ls /proc/xen"
wait

# -----------------------------------------------------------
p ""
p "# Check 3: Is the protect-daemon running?"
p "# Expected: 'active'"
pe "sudo systemctl is-active protect-daemon"
wait

# -----------------------------------------------------------
p ""
p "# Check 4: Zone lifecycle — launch, list, destroy"
p "# This confirms the full control path through the hypervisor"
pe "sudo protect zone launch -n test-zone --wait"
wait

pe "sudo protect zone list"
wait

pe "sudo protect zone destroy test-zone"
wait

# -----------------------------------------------------------
p ""
p "# If all checks above succeeded, Edera On is running correctly"
