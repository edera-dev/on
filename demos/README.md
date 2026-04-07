# Demos

These demos run on a remote EC2 instance after Edera On has been installed. Each demo includes a walkthrough README with copy-paste commands and an automated `test.sh` that validates the same checks programmatically.

## [Demo 00: Verify Edera On](DEMO_00/README.md)

Post-installation health check. Confirms the Edera kernel is booted, the Xen hypervisor is active, the protect-daemon is running, and that a zone can be launched and destroyed successfully. Run this first to verify the instance is ready for the remaining demos.

## [Demo 01: Container Escape vs Zone Isolation](DEMO_01/README.md)

Side-by-side comparison of Docker's shared-kernel model against Edera's VM-isolated zones. Part 1 shows what a privileged Docker container can reach (host processes, devices, filesystem). Part 2 runs the same checks inside Edera zones to demonstrate kernel, process, filesystem, and device isolation. Seven automated assertions validate the differences.

## [Demo 02: Agent Attack](DEMO_02/README.md)

Simulates a compromised AI agent running an 8-step automated escape script (`agent-escape.sh`). The script attempts process enumeration, AWS metadata credential theft, host filesystem traversal, kernel fingerprinting, and a reverse shell — first in a Docker container (where several attacks succeed), then in an Edera zone (where all attacks are blocked). Output uses `EXPOSED` / `BLOCKED` / `ISOLATED` markers to show the result of each attempt.

## Running Demo Scripts

Each demo includes a `demo.sh` script for video recording using [demo-magic](https://github.com/paxtonhare/demo-magic). These scripts simulate typing and pause between steps so the presenter can narrate.

### Prerequisites

Install `pv` (pipe viewer) on the remote instance — demo-magic uses it for simulated typing:

```sh
# Ubuntu/Debian
sudo apt-get install -y pv

# Amazon Linux
sudo dnf install -y pv
```

### Usage

```sh
# Interactive — press ENTER to advance between steps
./DEMO_00/demo.sh

# Non-interactive — auto-advance (useful for testing)
./DEMO_00/demo.sh -n

# Disable simulated typing (instant output)
./DEMO_00/demo.sh -d
```

### Tool Choice

**demo-magic** was chosen because:

- The presenter controls pacing with keypresses — ideal for live-narrated video recording
- Commands actually execute on the instance (not just displayed)
- Simulated typing creates a natural viewing experience
- Single vendored bash script (`demos/demo-magic.sh`) with no dependencies beyond `pv`
