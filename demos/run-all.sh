#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_START=$(date +%s)

for demo in DEMO_00 DEMO_01 DEMO_02; do
  echo ""
  echo "========================================"
  echo "  Running ${demo}"
  echo "========================================"
  bash "${SCRIPT_DIR}/${demo}/test.sh"
done

TOTAL_END=$(date +%s)
TOTAL_DURATION=$((TOTAL_END - TOTAL_START))

echo ""
echo "========================================"
echo "  ALL DEMOS COMPLETE (${TOTAL_DURATION}s total)"
echo "========================================"
