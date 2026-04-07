# Demo 01: Container Escape vs Zone Isolation

Side-by-side comparison showing what a privileged Docker container can reach versus what an Edera zone exposes. This is the core demo — it makes the security difference tangible by running identical commands in both environments.

## What This Proves

Docker containers share the host kernel. A container with `--pid=host` or `--privileged` can see host processes, access host devices, and traverse to the host filesystem. A kernel exploit in any container compromises the entire node.

Edera zones are lightweight VMs. Each zone runs its own kernel behind the Xen hypervisor. Even with the same commands, a zone cannot see host processes, access host devices, or reach the host filesystem — because there is a hardware-enforced VM boundary, not just a Linux namespace boundary.

## Part 1: The Problem — What Docker Exposes

Run these commands to see what a "hostile" Docker container can reach.

### Host Process Visibility

```sh
docker run --rm --pid=host alpine ps aux | head -20
```

**What's happening:** `--pid=host` shares the host's PID namespace with the container. The container can see every process on the host — including other containers, system daemons, and SSH sessions.

**Expected:** 50+ processes visible, including `systemd`, `dockerd`, `sshd`, and anything else running on the host.

### Privileged Device Access

```sh
docker run --rm --privileged alpine ls /dev | wc -l
```

**What's happening:** `--privileged` disables all security restrictions and gives the container access to every device on the host. This includes block devices (disks), network devices, and hardware.

**Expected:** 50+ devices visible. A non-privileged container typically sees ~15.

### Host Kernel (Shared)

```sh
docker run --rm alpine uname -r
```

**What's happening:** Every Docker container shares the host kernel. The version reported inside the container is the host's kernel version. A kernel vulnerability affects every container on the node simultaneously.

**Expected:** The same kernel version as the host (e.g. `6.x.y-edera`).

### Host Filesystem Traversal

```sh
docker run --rm --pid=host --privileged alpine cat /proc/1/root/etc/hostname
```

**What's happening:** With `--pid=host`, the container can see the host's PID 1 (init process). `/proc/1/root` is a symlink to PID 1's root filesystem — the host's actual root. This means the container can read any file on the host, including `/etc/shadow` (password hashes), SSH keys, and application secrets.

**Expected:** The host's actual hostname, proving the container has read access to the host filesystem.

## Part 2: The Fix — Same Workloads in Edera Zones

Now run the same checks inside Edera zones. First, create two isolated zones:

```sh
sudo protect zone launch -n zone-a --wait
sudo protect zone launch -n zone-b --wait
```

Two zones are needed to demonstrate that zones are also isolated from *each other*, not just from the host.

### Check 1: Kernel Isolation

```sh
# Host kernel
uname -r

# Zone kernel — each zone runs its OWN kernel
sudo protect workload launch --zone zone-a --name kernel-check -t -a \
  docker.io/library/alpine:latest uname -r
```

**What's happening:** Unlike Docker, each Edera zone boots its own kernel inside a Xen VM. The zone kernel version will differ from the host kernel.

**Expected:** The zone reports a different kernel version than the host. This means a kernel exploit inside zone-a cannot affect the host or zone-b — they are running entirely separate kernels.

### Check 2: Process Isolation

```sh
# Launch a long-running workload in zone-a
sudo protect workload launch --zone zone-a --name secret-app \
  docker.io/library/alpine:latest sleep 3600

# From zone-b, try to see zone-a's processes
sudo protect workload launch --zone zone-b --name spy -t -a \
  docker.io/library/alpine:latest ps aux
```

**What's happening:** A workload runs in zone-a. A separate workload in zone-b attempts to list all processes. Because each zone is a separate VM, zone-b's process list contains only its own processes.

**Expected:** Zone-b sees fewer than 10 processes (just its own `ps` and supporting processes). In Docker with `--pid=host`, this would show every process on the host including zone-a's workload.

### Check 3: Filesystem Isolation

```sh
sudo protect workload launch --zone zone-a --name fs-check -t -a \
  docker.io/library/alpine:latest cat /etc/hostname
```

**What's happening:** The workload reads `/etc/hostname` from inside the zone. Because the zone is a VM with its own filesystem, it sees its own hostname — not the host's.

**Expected:** A hostname different from the host's. There is no mount trick or `/proc` traversal that can reach the host filesystem because the zone is a VM boundary, not a namespace boundary.

### Check 4: Device Isolation

```sh
sudo protect workload launch --zone zone-a --name dev-check -t -a \
  docker.io/library/alpine:latest ls /dev
```

**What's happening:** The workload lists devices visible inside the zone. Because the zone is a VM, it only sees virtualised devices (virtual console, virtual disk) — not the host's physical hardware.

**Expected:** Significantly fewer devices than Docker's `--privileged` mode (which showed 50+). The zone only exposes the minimal set of virtual devices needed to run.

## Part 3: Clean Up

Remove all workloads and zones:

```sh
sudo protect workload destroy secret-app
sudo protect workload destroy kernel-check
sudo protect workload destroy spy
sudo protect workload destroy fs-check
sudo protect workload destroy dev-check
sudo protect zone destroy zone-a
sudo protect zone destroy zone-b
```

## Video Recording

Run `demo.sh` for a scripted walkthrough with simulated typing, suitable for video recording:

```sh
./demo.sh
```

Press ENTER to advance between steps. See [demos/README.md](../README.md#running-demo-scripts) for prerequisites and options.

## Automated Test

Run `test.sh` to validate all seven checks automatically:

```sh
./test.sh
```

The script runs three Docker exposure tests (process visibility, device access, filesystem traversal) and four Edera isolation tests (kernel, process, filesystem, device). It reports `[PASS]` or `[FAIL]` for each and cleans up all zones and workloads on exit.

| Test | Environment | What It Checks | Pass Condition |
|------|------------|----------------|----------------|
| 1 | Docker | Host process visibility | Sees > 10 host processes |
| 2 | Docker | Privileged device access | Sees > 50 devices |
| 3 | Docker | Filesystem traversal | Reads host hostname via `/proc/1/root` |
| 4 | Zone | Kernel isolation | Zone kernel differs from host kernel |
| 5 | Zone | Process isolation | Zone-b sees < 10 processes (can't see zone-a) |
| 6 | Zone | Filesystem isolation | Zone hostname differs from host hostname |
| 7 | Zone | Device isolation | Zone sees fewer devices than Docker privileged |
