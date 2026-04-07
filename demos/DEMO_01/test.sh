#!/usr/bin/env bash
set -euo pipefail

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
  echo "==> Cleaning up zones and workloads..."
  sudo protect workload destroy secret-app 2>/dev/null || true
  sudo protect workload destroy kernel-check 2>/dev/null || true
  sudo protect workload destroy spy 2>/dev/null || true
  sudo protect workload destroy fs-check 2>/dev/null || true
  sudo protect workload destroy dev-check 2>/dev/null || true
  sudo protect zone destroy zone-a 2>/dev/null || true
  sudo protect zone destroy zone-b 2>/dev/null || true
}
trap cleanup EXIT

HOST_HOSTNAME=$(hostname)
HOST_KERNEL=$(uname -r)

echo "============================================"
echo "  DEMO 01: Container Escape vs Zone Isolation"
echo "============================================"
echo ""
echo "Host hostname: ${HOST_HOSTNAME}"
echo "Host kernel:   ${HOST_KERNEL}"
echo ""

# ==========================================================
# Part 1: Docker (expect exposure)
# ==========================================================
echo "--- Part 1: Docker (expect exposure) ---"
echo ""

# Test 1: Docker sees host processes
echo "[1] Docker: host process visibility with --pid=host..."
DOCKER_PS_COUNT=$(docker run --rm --pid=host alpine ps aux 2>/dev/null | wc -l)
echo "    Processes visible: ${DOCKER_PS_COUNT}"
if [ "${DOCKER_PS_COUNT}" -gt 10 ]; then
  pass "Docker sees host processes (${DOCKER_PS_COUNT} processes)"
else
  fail "Docker did not see host processes (only ${DOCKER_PS_COUNT})"
fi
echo ""

# Test 2: Docker privileged sees many devices
echo "[2] Docker: privileged device access..."
DOCKER_DEV_COUNT=$(docker run --rm --privileged alpine ls /dev 2>/dev/null | wc -l)
echo "    Devices visible: ${DOCKER_DEV_COUNT}"
if [ "${DOCKER_DEV_COUNT}" -gt 50 ]; then
  pass "Docker privileged sees many devices (${DOCKER_DEV_COUNT})"
else
  fail "Docker privileged sees fewer devices than expected (${DOCKER_DEV_COUNT})"
fi
echo ""

# Test 3: Docker reads host hostname via PID namespace traversal
echo "[3] Docker: host filesystem access via /proc/1/root..."
DOCKER_HOSTNAME=$(docker run --rm --pid=host --privileged alpine cat /proc/1/root/etc/hostname 2>/dev/null || true)
echo "    Docker read hostname: ${DOCKER_HOSTNAME}"
if [ "${DOCKER_HOSTNAME}" = "${HOST_HOSTNAME}" ]; then
  pass "Docker reads host hostname via PID namespace traversal"
else
  fail "Docker hostname mismatch (got: '${DOCKER_HOSTNAME}', expected: '${HOST_HOSTNAME}')"
fi
echo ""

# ==========================================================
# Part 2: Edera Zones (expect isolation)
# ==========================================================
echo "--- Part 2: Edera Zones (expect isolation) ---"
echo ""

echo "==> Launching zones..."
ZONE_A_START=$(date +%s)
sudo protect zone launch -n zone-a --wait
ZONE_A_END=$(date +%s)
echo "    zone-a launch: $((ZONE_A_END - ZONE_A_START))s"
ZONE_B_START=$(date +%s)
sudo protect zone launch -n zone-b --wait
ZONE_B_END=$(date +%s)
echo "    zone-b launch: $((ZONE_B_END - ZONE_B_START))s"
echo ""

# Test 4: Zone kernel differs from host
echo "[4] Zone: kernel isolation..."
ZONE_KERNEL=$(sudo protect workload launch --zone zone-a --name kernel-check -t -a \
  docker.io/library/alpine:latest uname -r 2>/dev/null | awk 'NF{line=$0} END{print line}')
echo "    Zone kernel: ${ZONE_KERNEL}"
if [ "${ZONE_KERNEL}" != "${HOST_KERNEL}" ]; then
  pass "Zone runs a different kernel than the host"
else
  fail "Zone kernel matches host kernel (no isolation)"
fi
echo ""

# Test 5: Process isolation between zones
echo "[5] Zone: process isolation..."
sudo protect workload launch --zone zone-a --name secret-app \
  docker.io/library/alpine:latest sleep 3600
# Give the workload a moment to start
sleep 2
ZONE_B_PS=$(sudo protect workload launch --zone zone-b --name spy -t -a \
  docker.io/library/alpine:latest ps aux 2>/dev/null || true)
ZONE_B_PS_COUNT=$(echo "${ZONE_B_PS}" | awk 'NF' | wc -l)
echo "    Zone-b sees ${ZONE_B_PS_COUNT} processes"
if [ "${ZONE_B_PS_COUNT}" -lt 10 ]; then
  pass "Zone-b cannot see zone-a's processes (only ${ZONE_B_PS_COUNT} lines)"
else
  fail "Zone-b sees too many processes (${ZONE_B_PS_COUNT} — possible leak)"
fi
echo ""

# Test 6: Filesystem isolation
echo "[6] Zone: filesystem isolation..."
ZONE_HOSTNAME=$(sudo protect workload launch --zone zone-a --name fs-check -t -a \
  docker.io/library/alpine:latest cat /etc/hostname 2>/dev/null | awk 'NF{line=$0} END{print line}')
echo "    Zone hostname: ${ZONE_HOSTNAME}"
if [ "${ZONE_HOSTNAME}" != "${HOST_HOSTNAME}" ]; then
  pass "Zone sees its own hostname, not the host's"
else
  fail "Zone hostname matches host (no filesystem isolation)"
fi
echo ""

# Test 7: Device isolation
echo "[7] Zone: device isolation..."
ZONE_DEV_COUNT=$(sudo protect workload launch --zone zone-a --name dev-check -t -a \
  docker.io/library/alpine:latest ls /dev 2>/dev/null | wc -l)
echo "    Zone devices: ${ZONE_DEV_COUNT}"
if [ "${ZONE_DEV_COUNT}" -lt "${DOCKER_DEV_COUNT}" ]; then
  pass "Zone sees fewer devices than Docker privileged (${ZONE_DEV_COUNT} vs ${DOCKER_DEV_COUNT})"
else
  fail "Zone sees as many or more devices than Docker (${ZONE_DEV_COUNT} vs ${DOCKER_DEV_COUNT})"
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
