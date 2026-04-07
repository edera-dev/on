#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PASSED=0
FAILED=0
SCRIPT_START=$(date +%s)

pass() {
  echo "  [PASS] $1"
  PASSED=$((PASSED + 1))
}

fail() {
  echo "  [FAIL] $1"
  FAILED=$((FAILED + 1))
}

cleanup() {
  echo ""
  echo "==> Cleaning up..."
  sudo protect workload destroy rogue-agent 2>/dev/null || true
  sudo protect zone destroy agent-sandbox 2>/dev/null || true
  rm -f "${DOCKER_OUTPUT}" "${ZONE_OUTPUT}" 2>/dev/null || true
}

DOCKER_OUTPUT=$(mktemp)
ZONE_OUTPUT=$(mktemp)
trap cleanup EXIT

AGENT_SCRIPT="${SCRIPT_DIR}/scripts/agent-escape.sh"
if [ ! -f "${AGENT_SCRIPT}" ]; then
  echo "ERROR: agent-escape.sh not found at ${AGENT_SCRIPT}"
  exit 1
fi

echo "============================================"
echo "  DEMO 02: Agent Attack Simulation"
echo "============================================"
echo ""

# ==========================================================
# Part 1: Docker (expect exposure)
# ==========================================================
echo "--- Part 1: Agent in Docker (expect vulnerabilities) ---"
echo ""

echo "==> Running agent-escape.sh in Docker with --pid=host..."
DOCKER_START=$(date +%s)
docker run --rm --pid=host \
  -v "${AGENT_SCRIPT}":/agent-escape.sh:ro \
  alpine sh /agent-escape.sh > "${DOCKER_OUTPUT}" 2>&1 || true
DOCKER_END=$(date +%s)
echo "    Docker agent run: $((DOCKER_END - DOCKER_START))s"

DOCKER_EXPOSED=$(grep -c ">>> EXPOSED:" "${DOCKER_OUTPUT}" || true)
DOCKER_BLOCKED=$(grep -c ">>> BLOCKED:\|>>> ISOLATED:" "${DOCKER_OUTPUT}" || true)
echo "    EXPOSED markers:  ${DOCKER_EXPOSED}"
echo "    BLOCKED/ISOLATED: ${DOCKER_BLOCKED}"

# Test 1: Docker run shows at least one EXPOSED marker
echo ""
echo "[1] Docker: agent finds vulnerabilities..."
if [ "${DOCKER_EXPOSED}" -gt 0 ]; then
  pass "Agent found ${DOCKER_EXPOSED} exposure(s) in Docker"
else
  fail "Agent found no exposures in Docker (expected at least one)"
fi
echo ""

# ==========================================================
# Part 2: Edera Zone (expect isolation)
# ==========================================================
echo "--- Part 2: Agent in Edera Zone (expect isolation) ---"
echo ""

echo "==> Launching agent-sandbox zone..."
ZONE_START=$(date +%s)
sudo protect zone launch -n agent-sandbox --wait
ZONE_END=$(date +%s)
echo "    Zone launch: $((ZONE_END - ZONE_START))s"

echo "==> Running agent-escape.sh in Edera zone..."
ZONE_AGENT_START=$(date +%s)
sudo protect workload launch \
  --zone agent-sandbox \
  --name rogue-agent \
  -m "${AGENT_SCRIPT}":/agent-escape.sh \
  -t -a \
  docker.io/library/alpine:latest sh /agent-escape.sh > "${ZONE_OUTPUT}" 2>&1 || true
ZONE_AGENT_END=$(date +%s)
echo "    Zone agent run: $((ZONE_AGENT_END - ZONE_AGENT_START))s"

ZONE_EXPOSED=$(grep -c ">>> EXPOSED:" "${ZONE_OUTPUT}" || true)
ZONE_BLOCKED=$(grep -c ">>> BLOCKED:\|>>> ISOLATED:" "${ZONE_OUTPUT}" || true)
echo "    EXPOSED markers:  ${ZONE_EXPOSED}"
echo "    BLOCKED/ISOLATED: ${ZONE_BLOCKED}"
echo ""

# Test 2: Zone run shows zero EXPOSED markers
echo "[2] Zone: agent escape attempts are blocked..."
if [ "${ZONE_EXPOSED}" -eq 0 ]; then
  pass "Agent found no exposures in Edera zone"
else
  fail "Agent found ${ZONE_EXPOSED} exposure(s) in Edera zone (expected 0)"
fi
echo ""

# Test 3: Zone run shows at least one BLOCKED/ISOLATED marker
echo "[3] Zone: agent hits isolation boundaries..."
if [ "${ZONE_BLOCKED}" -gt 0 ]; then
  pass "Agent hit ${ZONE_BLOCKED} isolation boundary(ies)"
else
  fail "Agent found no isolation markers (expected BLOCKED or ISOLATED)"
fi
echo ""

# Summary
SCRIPT_END=$(date +%s)
echo "============================================"
echo "  RESULTS: ${PASSED} passed, ${FAILED} failed"
echo "  Total time: $((SCRIPT_END - SCRIPT_START))s"
echo "============================================"

if [ "${FAILED}" -gt 0 ]; then
  exit 1
fi
