# Demo 02: Agent Attack

Simulates a compromised AI agent attempting to escape its container. The `agent-escape.sh` script runs 8 automated attack techniques and labels each result as `EXPOSED`, `BLOCKED`, or `ISOLATED`. First run in Docker (where several attacks succeed), then in an Edera zone (where all attacks are blocked).

## What This Proves

An AI agent with code execution capability is a real-world threat model. If the agent runs in a Docker container, it can enumerate host processes, steal AWS credentials from the metadata service, read the host filesystem, and attempt reverse shells. Edera zones eliminate these attack vectors by running each workload in a VM — the agent never shares a kernel, PID namespace, or network path with the host.

## The Attack Script

`scripts/agent-escape.sh` runs 8 sequential escape attempts:

| Step | Attack | What It Tries | Docker Result | Zone Result |
|------|--------|--------------|---------------|-------------|
| 1 | **Recon** | Enumerate hostname, kernel, user | Informational | Informational |
| 2 | **Host Process Enumeration** | Read `/proc/1/cmdline`, count visible processes | `EXPOSED` — sees host PID 1 and 50+ processes | `ISOLATED` — sees only its own processes |
| 3 | **AWS Metadata Service** | Fetch IAM credentials from `169.254.169.254` | `EXPOSED` or `BLOCKED` (depends on instance role) | `BLOCKED` — metadata service unreachable |
| 4 | **Host Network Scanning** | Ping the default gateway | `EXPOSED` or `LIMITED` | `BLOCKED` — no gateway route |
| 5 | **Host Filesystem Access** | Read `/etc/shadow` via `/proc/1/root` | `EXPOSED` — reads host password hashes | `BLOCKED` or `ISOLATED` — traversal fails |
| 6 | **Container Escape via /proc/self/root** | Path traversal to reach host filesystem | `EXPOSED` — reaches different filesystem | `ISOLATED` — loops back to own filesystem |
| 7 | **Kernel Exploit Surface** | Check if kernel is shared with host | `EXPOSED` — shared kernel means shared exploits | `ISOLATED` — own kernel behind hypervisor |
| 8 | **Reverse Shell Attempt** | Outbound TCP connection to host port 4444 | `EXPOSED` or `BLOCKED` (depends on listener) | `BLOCKED` — connection fails |

### Output Markers

Each attack prints one of these markers:

- **`>>> EXPOSED:`** — the attack succeeded. The agent accessed something it should not have.
- **`>>> BLOCKED:`** — the attack failed completely. The resource was unreachable.
- **`>>> ISOLATED:`** — the attack ran but hit a VM boundary. The agent could see its own environment but not the host's.
- **`>>> LIMITED:`** — partial access. The gateway is visible but services are unreachable.

## Run 1: Agent in Docker (Unprotected)

```sh
docker run --rm --pid=host \
  -v /tmp/agent-escape.sh:/agent-escape.sh:ro \
  alpine sh /agent-escape.sh
```

**What's happening:** The agent runs with `--pid=host`, which gives it access to the host's PID namespace. It shares the host kernel and can see host processes, traverse to the host filesystem via `/proc/1/root`, and potentially reach the AWS metadata service.

**Expected:** Multiple `EXPOSED` markers. The agent can see host processes, read the host filesystem, and is running the same kernel as the host.

## Run 2: Agent in an Edera Zone (Isolated)

```sh
# Create a zone for the agent
sudo protect zone launch -n agent-sandbox --wait

# Run the same attack script in the zone
sudo protect workload launch \
  --zone agent-sandbox \
  --name rogue-agent \
  -m /tmp/agent-escape.sh:/agent-escape.sh \
  -t -a \
  docker.io/library/alpine:latest sh /agent-escape.sh
```

**What's happening:** The identical attack script runs inside an Edera zone. The zone is a Xen VM with its own kernel, PID namespace, filesystem, and network stack. Every escape technique that worked in Docker now fails.

**Expected:** Zero `EXPOSED` markers. Every attack is either `BLOCKED` (unreachable) or `ISOLATED` (hits the VM boundary and loops back to its own environment).

## Run 3: Interactive Agent Shell (Optional)

For a live walkthrough where you type commands as the "agent":

```sh
sudo protect workload launch \
  --zone agent-sandbox \
  --name agent-shell \
  -t -a \
  docker.io/library/alpine:latest sh
```

Then try each attack manually inside the shell:

```sh
# Try to steal AWS credentials
wget -q -O - http://169.254.169.254/latest/meta-data/iam/security-credentials/

# Try to see host processes
ls /proc/*/cmdline 2>/dev/null | wc -l

# Try to read host files
cat /proc/1/root/etc/shadow

# Check the kernel — is it the host kernel?
uname -r
```

**Expected:** Every command either fails or returns only zone-local information. The agent is trapped inside the VM boundary.

## Clean Up

```sh
sudo protect workload destroy rogue-agent
sudo protect workload destroy agent-shell
sudo protect zone destroy agent-sandbox
```

## Video Recording

Run `demo.sh` for a scripted walkthrough with simulated typing, suitable for video recording:

```sh
./demo.sh
```

Press ENTER to advance between steps. See [demos/README.md](../README.md#running-demo-scripts) for prerequisites and options.

## Automated Test

Run `test.sh` to validate the attack results automatically:

```sh
./test.sh
```

The script runs `agent-escape.sh` in Docker and in an Edera zone, captures the output, and counts the markers.

| Test | What It Checks | Pass Condition |
|------|---------------|----------------|
| 1 | Docker: agent finds vulnerabilities | At least 1 `EXPOSED` marker |
| 2 | Zone: escape attempts are blocked | Zero `EXPOSED` markers |
| 3 | Zone: agent hits isolation boundaries | At least 1 `BLOCKED` or `ISOLATED` marker |

The test uses the script at `scripts/agent-escape.sh` (relative to the demo directory) and cleans up temporary output files and the zone on exit.
