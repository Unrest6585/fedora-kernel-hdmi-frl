# Fedora Kernel with HDMI 2.1 FRL Support

> [!WARNING]
> **Phased out.** This project no longer builds new kernels. Both COPR repositories (`sneed/kernel-hdmi-frl` and `sneed/kernel-hdmi-frl-p2p`) are frozen at their last builds (Linux 7.1.13) and will not receive updates, including security fixes. Fedora 44 ships Linux 7.2, which covers both use cases with the stock kernel:
>
> - **HDMI 2.1 FRL** is upstream in Linux 7.2 (enable it with `amdgpu.dcfeaturemask=0x400`, see below).
> - **ROCm P2P** (`CONFIG_HSA_AMD_P2P`) no longer depends on `CONFIG_DMABUF_MOVE_NOTIFY` in Linux 7.2 and is enabled in Fedora's stock kernel config.
>
> Disable the COPR repository and switch to Fedora's kernel:
>
> ```bash
> sudo dnf copr disable sneed/kernel-hdmi-frl      # or sneed/kernel-hdmi-frl-p2p
> sudo dnf upgrade --refresh kernel
> ```

These were compatibility builds of Fedora's stable Linux 7.1 kernel with mkopec's HDMI 2.1 FRL (Fixed Rate Link) patches for AMDGPU, plus an optional ROCm P2P-enabled variant.

## Linux 7.2 and Newer

Use Fedora's stock kernel and enable the upstream AMD HDMI FRL implementation, which is currently disabled by default:

```bash
sudo grubby --update-kernel=ALL --args="amdgpu.dcfeaturemask=0x400"
sudo reboot
```

If `amdgpu.dcfeaturemask` is already set, combine its existing bits with `0x400` instead of adding a second value.

## Patches Included

For Linux 7.1 only, the repository carries a squashed, kernel-only compatibility patch from [mkopec/linux hdmi_frl](https://github.com/mkopec/linux/tree/hdmi_frl), rebased onto Fedora 44's kernel. It includes:

- HPO (High-Performance Output) HDMI encoder support for newer DCN generations
- HDMI FRL link validation and bandwidth checking
- DTBCLK programming for HDMI FRL
- HDMI FRL signal upgrade and rate negotiation
- EDID FRL and HDMI DSC capability parsing improvements
- HDMI VRR (Variable Refresh Rate) support
- ALLM (Auto Low Latency Mode) support
- YCbCr 4:2:0 handling
- HDMI audio fixes for FRL
- DPMS and shutdown handling updates
- Passive VRR properties

## Installation

### From COPR (Recommended)

```bash
# Enable the default FRL COPR repository
sudo dnf copr enable sneed/kernel-hdmi-frl

# Install the patched kernel
sudo dnf install kernel

# Reboot to use the new kernel
sudo reboot
```

For the ROCm P2P-enabled variant:

```bash
sudo dnf copr enable sneed/kernel-hdmi-frl-p2p
sudo dnf install kernel
sudo reboot
```

Do not enable both COPRs at the same time. Both publish `kernel` packages, so keeping a single variant enabled avoids ambiguous update selection.

### Manual Build

```bash
# Install build dependencies
sudo dnf install rpm-build rpmdevtools koji cpio

# Clone this repository
git clone https://github.com/sneed/fedora-kernel-hdmi-frl.git
cd fedora-kernel-hdmi-frl

# Run the default FRL build
./build.sh

# Or build the ROCm P2P-enabled variant
ENABLE_P2P=1 ./build.sh

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

The scheduled and push triggers have been removed since the project was phased out. The workflow can still be run manually via workflow_dispatch, but it skips Linux 7.2 and newer.

The workflow publishes both `sneed/kernel-hdmi-frl` and `sneed/kernel-hdmi-frl-p2p`, and tracks their last built Fedora kernel NVR independently.

## Upstream Source

- **Patches from**: [mkopec/linux hdmi_frl](https://github.com/mkopec/linux/tree/hdmi_frl)
- **Authors**: Michal Kopec, Tomasz Pakula

## License

The patches are licensed under GPL-2.0, matching the Linux kernel license.
