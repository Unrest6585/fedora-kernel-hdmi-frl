# Fedora Kernel with HDMI 2.1 FRL Patches

Automated builds of the Fedora 43 kernel with mkopec's HDMI 2.1 FRL (Fixed Rate Link) patches for AMDGPU. The current patch is based on the experimental `hdmi_frl` branch and is being tested against Fedora 43 kernel 7.0.1.

## Patches Included

Single squashed, kernel-only patch from [mkopec/linux hdmi_frl](https://github.com/mkopec/linux/tree/hdmi_frl), enabling HDMI 2.1 FRL support on AMD GPUs. This includes:

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

The workflow runs:
- **Daily** at 6 AM UTC to check for new kernels
- **On push** when patches or workflow files change
- **Manually** via workflow_dispatch (with optional force build)

The workflow publishes both `sneed/kernel-hdmi-frl` and `sneed/kernel-hdmi-frl-p2p`, and tracks their last built Fedora kernel NVR independently.

## Upstream Source

- **Patches from**: [mkopec/linux hdmi_frl](https://github.com/mkopec/linux/tree/hdmi_frl)
- **Authors**: Michal Kopec, Tomasz Pakula

## License

The patches are licensed under GPL-2.0, matching the Linux kernel license.
