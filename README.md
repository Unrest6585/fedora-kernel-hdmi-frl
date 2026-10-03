# Fedora Kernel with HDMI 2.1 FRL and FreeSync

Builds of Fedora 44's stable Linux 7.2 kernel with two small AMDGPU fixes that make HDMI 2.1 work out of the box, including FreeSync/VRR. Intended as a stopgap until both changes are in Fedora's kernel.

Linux 7.2 ships native AMD HDMI 2.1 FRL (Fixed Rate Link) support, but:

1. **FRL is disabled by default** and needs `amdgpu.dcfeaturemask=0x402`.
2. **VRR disappears as soon as FRL is active.** FRL sinks are detected as `SIGNAL_TYPE_HDMI_FRL`, but `amdgpu_dm_update_freesync_caps()` only parses the AMD FreeSync data block for `SIGNAL_TYPE_HDMI_TYPE_A`, so `vrr_capable` stays `0` (e.g. LG C1/C4 at 4K@120). See [ValveSoftware/SteamOS#2809](https://github.com/ValveSoftware/SteamOS/issues/2809).

## Patches Included

`patches/7.2/` (Linux 7.2 only):

| Patch | Description | Upstream |
|-------|-------------|----------|
| `0001-drm-amd-display-parse-amd-vsdb-for-hdmi-frl-sinks.patch` | Use `dc_is_hdmi_signal()` so FreeSync is detected on FRL links | Same change as Tomasz Pakuła's "Switch to signal type helper functions from DC" (`Lawstorant/linux` `hdmi-7.2`); not in mainline yet |
| `0002-drm-amd-display-enable-hdmi-frl-by-default.patch` | Add `DC_FRL_MASK` to the default `dcfeaturemask` (`0x402`) | Backport of AMD's reviewed [patch](https://ratatoskr.run/amd-gfx/2026/08/17470579/t), expected in Linux 7.4 |

Setting `amdgpu.dcfeaturemask` explicitly still overrides the default, e.g. `amdgpu.dcfeaturemask=0x2` turns FRL off again.

Not included: HDMI Forum VRR (VTEM) and ALLM. Displays that only support HDMI Forum VRR without FreeSync get no VRR until AMD's HDMI VRR/ALLM series lands (expected in Linux 7.4).

Builds for Linux 7.1 used a squashed compatibility patch from [mkopec/linux hdmi_frl](https://github.com/mkopec/linux/tree/hdmi_frl); it was retired with Linux 7.2 and is still available in the git history.

### ROCm P2P

Since Linux 7.2, `CONFIG_HSA_AMD_P2P` no longer depends on `CONFIG_DMABUF_MOVE_NOTIFY` and is enabled in Fedora's stock config, so these kernels support ROCm P2P without changes. The separate `sneed/kernel-hdmi-frl-p2p` COPR was removed; if you still have it configured, run `sudo dnf copr remove sneed/kernel-hdmi-frl-p2p` and enable `sneed/kernel-hdmi-frl` instead.

## Installation

### From COPR (Recommended)

```bash
# Enable the COPR repository
sudo dnf copr enable sneed/kernel-hdmi-frl

# Install the patched kernel
sudo dnf install kernel

# Reboot to use the new kernel
sudo reboot
```

No kernel parameter is needed. If you added `amdgpu.dcfeaturemask=0x402` earlier, you can keep or remove it; replace a bare `0x400`, which also clears the default `0x2` bit (`sudo grubby --update-kernel=ALL --remove-args=amdgpu.dcfeaturemask`). Enable FreeSync on the display (on LG TVs: Game Optimizer -> AMD FreeSync Premium) and check:

```bash
cat /sys/module/amdgpu/parameters/dcfeaturemask   # 1026 (= 0x402)
```


### Manual Build

```bash
# Install build dependencies
sudo dnf install rpm-build rpmdevtools koji cpio

# Clone this repository
git clone https://github.com/sneed/fedora-kernel-hdmi-frl.git
cd fedora-kernel-hdmi-frl

# Build the SRPM for the newest Fedora 44 kernel
./build.sh

# Or pin a kernel
KERNEL_NVR=kernel-7.2.8-200.fc44 ./build.sh

# Install the resulting SRPM or build locally
rpmbuild --rebuild kernel-*.src.rpm
```

## GitHub Actions Setup

To enable automatic builds when new Fedora kernels are released:

### 1. Create a COPR API Token

1. Go to https://copr.fedorainfracloud.org/api/
2. Log in with your Fedora Account
3. Copy your API credentials

### 2. Add GitHub Secrets

Add these secrets to your repository (Settings -> Secrets and variables -> Actions):

| Secret | Description |
|--------|-------------|
| `COPR_LOGIN` | Your COPR login token |
| `COPR_USERNAME` | Your COPR/Fedora username |
| `COPR_TOKEN` | Your COPR API token |

### 3. Workflow Triggers

The workflow runs:
- **Daily** at 6 AM UTC to check for new kernels
- **On push** when patches or workflow files change
- **Manually** via workflow_dispatch (with optional force build)

Kernels older than Linux 7.2 are skipped.

The workflow publishes `sneed/kernel-hdmi-frl` and tracks the last built Fedora kernel NVR in `state/last_nvr_default`.

## Upstream Source

- **FreeSync over FRL fix**: same change as Tomasz Pakuła's `hdmi-7.2` branch (`Lawstorant/linux`)
- **FRL default**: Fangzhi Zuo (AMD), reviewed by Harry Wentland
- **Linux 7.1 patch (retired)**: [mkopec/linux hdmi_frl](https://github.com/mkopec/linux/tree/hdmi_frl), Michal Kopec, Tomasz Pakuła

## License

The patches are licensed under GPL-2.0, matching the Linux kernel license.
