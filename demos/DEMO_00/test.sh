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
  echo "==> Cleaning up..."
  sudo protect zone destroy test-zone 2>/dev/null || true
}
trap cleanup EXIT

echo "============================================"
echo "  DEMO 00: Verify Edera On"
echo "============================================"
echo ""

# Test 1: Edera kernel
echo "[1] Checking kernel contains 'edera'..."
KERNEL=$(uname -r)
echo "    Kernel: ${KERNEL}"
if echo "${KERNEL}" | grep -q "edera"; then
  pass "Kernel contains 'edera'"
else
  fail "Kernel does not contain 'edera' (got: ${KERNEL})"
fi
echo ""

# Test 2: /proc/xen exists
echo "[2] Checking /proc/xen exists..."
if [ -d /proc/xen ]; then
  pass "/proc/xen exists"
else
  fail "/proc/xen does not exist"
fi
echo ""

# Test 3: protect-daemon is active
echo "[3] Checking protect-daemon is active..."
STATUS=$(sudo systemctl is-active protect-daemon 2>/dev/null || true)
echo "    Status: ${STATUS}"
if [ "${STATUS}" = "active" ]; then
  pass "protect-daemon is active"
else
  fail "protect-daemon is not active (got: ${STATUS})"
fi
echo ""

# Test 4: Zone lifecycle (launch + destroy)
echo "[4] Testing zone lifecycle (launch and destroy)..."
LAUNCH_START=$(date +%s)
if sudo protect zone launch -n test-zone --wait; then
  LAUNCH_END=$(date +%s)
  echo "    Zone launch: $((LAUNCH_END - LAUNCH_START))s"
  pass "Zone launched successfully"
  DESTROY_START=$(date +%s)
  if sudo protect zone destroy test-zone; then
    DESTROY_END=$(date +%s)
    echo "    Zone destroy: $((DESTROY_END - DESTROY_START))s"
    pass "Zone destroyed successfully"
  else
    fail "Zone destroy failed"
  fi
else
  fail "Zone launch failed"
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
