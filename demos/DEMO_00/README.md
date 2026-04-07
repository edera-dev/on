# Demo 00: Verify Edera On

Post-installation health check to confirm Edera On is running correctly. Run this before attempting any other demos.

## What This Proves

After the Edera installer reboots the instance, three things must be true for zones to work:

1. **Edera kernel is booted** — the installer replaces the stock Linux kernel with an Edera-patched kernel that includes Xen hypervisor support.
2. **Xen hypervisor is active** — Edera zones are lightweight VMs, not containers. The Xen hypervisor must be running for VM isolation to work.
3. **protect-daemon is running** — this is the Edera control plane daemon that manages zone lifecycle (launch, list, destroy).

If any of these are missing, the instance did not install correctly and needs to be re-provisioned.

## Verify After Reboot

### Check 1: Edera Kernel

```sh
uname -r
```

**Expected:** A version string containing `edera`, e.g. `6.x.y-edera`. If you see a stock kernel like `6.8.0-1021-aws`, the Edera kernel did not install or the instance booted from the wrong image.

### Check 2: Xen Hypervisor

```sh
ls /proc/xen
```

**Expected:** A directory listing (e.g. `capabilities xenbus ...`). If `/proc/xen` does not exist, the Xen hypervisor is not active and zones cannot run.

### Check 3: protect-daemon

```sh
sudo systemctl is-active protect-daemon
```

**Expected:** `active`. If the daemon is `inactive` or `failed`, check logs with `sudo journalctl -u protect-daemon` for errors.

### Check 4: Zone Lifecycle

Launch a test zone, verify it appears in the zone list, then destroy it:

```sh
sudo protect zone launch -n test-zone --wait
sudo protect zone list
sudo protect zone destroy test-zone
```

**Expected:** The zone launches without errors, appears in `zone list`, and is destroyed cleanly. This confirms the full control path — from the daemon through the hypervisor to a running VM and back.

## Video Recording

Run `demo.sh` for a scripted walkthrough with simulated typing, suitable for video recording:

```sh
./demo.sh
```

Press ENTER to advance between steps. See [demos/README.md](../README.md#running-demo-scripts) for prerequisites and options.

## Automated Test

Run `test.sh` to validate all four checks automatically:

```sh
./test.sh
```

The script runs each check above and reports `[PASS]` or `[FAIL]` for each. It cleans up the test zone on exit (even if a test fails).

## Tear Down

When you are finished with all demos, deactivate your license first at [on.edera.dev](https://on.edera.dev) so you can reuse it, then terminate the instance:

```sh
aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"
```
