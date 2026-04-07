#!/usr/bin/env bash
# Note: set -euo pipefail is intentionally omitted — demo-magic manages
# execution flow and uses eval, which is incompatible with errexit.

########################
# Demo 02: Agent Attack Simulation
#
# Scripted demo for video recording using demo-magic.
# Press ENTER to advance between steps.
#
# Prerequisites:
#   - pv installed (apt-get install pv / brew install pv)
#   - Docker installed and running
#   - Edera On installed and instance rebooted
#   - ./scripts/agent-escape.sh exists relative to this demo (auto-copied to /tmp at runtime)
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

# Ensure agent-escape.sh is available
AGENT_SCRIPT="${SCRIPT_DIR}/scripts/agent-escape.sh"
if [ ! -f "${AGENT_SCRIPT}" ]; then
  echo "ERROR: agent-escape.sh not found at ${AGENT_SCRIPT}" >&2
  exit 1
fi

# Copy to /tmp so the mount path matches the README examples
cp "${AGENT_SCRIPT}" /tmp/agent-escape.sh || {
  echo "ERROR: Failed to copy agent-escape.sh to /tmp" >&2
  exit 1
}

clear

p "# Demo 02: Agent Attack Simulation"
p "# A compromised AI agent attempts 8 escape techniques"
p "# First in Docker (attacks succeed), then in an Edera zone (all blocked)"
wait

# ===========================================================
# Part 1: Docker
# ===========================================================
p ""
p "# ═══════════════════════════════════════════"
p "# Run 1: Agent in Docker (Unprotected)"
p "# ═══════════════════════════════════════════"
p "# The agent runs with --pid=host — it shares the host kernel,"
p "# PID namespace, and can reach the host filesystem"
wait

pe "docker run --rm --pid=host -v /tmp/agent-escape.sh:/agent-escape.sh:ro alpine sh /agent-escape.sh"
wait

p ""
p "# Multiple EXPOSED markers — the agent accessed things it should not have"
wait

# ===========================================================
# Part 2: Edera Zone
# ===========================================================
p ""
p "# ═══════════════════════════════════════════"
p "# Run 2: Agent in an Edera Zone (Isolated)"
p "# ═══════════════════════════════════════════"
p "# The identical attack script runs inside a Xen VM"
p "# with its own kernel, PID namespace, and network stack"
wait

pe "sudo protect zone launch -n agent-sandbox --wait"
wait

pe "sudo protect workload launch --zone agent-sandbox --name rogue-agent -m /tmp/agent-escape.sh:/agent-escape.sh -t -a docker.io/library/alpine:latest sh /agent-escape.sh"
wait

p ""
p "# Zero EXPOSED markers — every attack is BLOCKED or ISOLATED"
wait

# ===========================================================
# Cleanup
# ===========================================================
p ""
p "# ═══════════════════════════════════════════"
p "# Cleanup"
p "# ═══════════════════════════════════════════"
pe "sudo protect workload destroy rogue-agent"
pe "sudo protect zone destroy agent-sandbox"
wait

p ""
p "# Same script, same commands — completely different outcome"
p "# Docker: shared kernel = shared risk"
p "# Edera:  VM boundary = hardware isolation"
