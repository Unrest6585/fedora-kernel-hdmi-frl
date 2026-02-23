# Fedora Kernel with HDMI 2.1 FRL Patches

Automated builds of the Fedora 43 kernel with mkopec's HDMI 2.1 FRL (Fixed Rate Link) patches for AMDGPU.

## Patches Included

Single squashed patch from [mkopec/linux hdmi_frl_amd_staging](https://github.com/mkopec/linux/tree/hdmi_frl_amd_staging) branch (80 commits), enabling HDMI 2.1 FRL support on AMD GPUs. This includes:

- HPO (High-Performance Output) HDMI encoder instantiation for DCN 3.1-3.6
- HDMI FRL link validation and bandwidth checking
- DTBCLK programming for HDMI FRL
- HDMI FRL signal upgrade and rate negotiation
- HDMI DSC (Display Stream Compression) support over FRL
- EDID FRL capability parsing improvements
- HDMI VRR (Variable Refresh Rate) support
- ALLM (Auto Low Latency Mode) support
- Passive VRR properties

## Installation

### From COPR (Recommended)

```bash
# Enable the COPR repository
sudo dnf copr enable YOUR_USERNAME/kernel-hdmi-frl

# Install the patched kernel
sudo dnf install kernel

# Reboot to use the new kernel
sudo reboot
```

### Manual Build

```bash
# Install build dependencies
sudo dnf install rpm-build rpmdevtools dnf-plugins-core cpio

# Clone this repository
git clone https://github.com/YOUR_USERNAME/fedora-kernel-hdmi-frl.git
cd fedora-kernel-hdmi-frl

# Run the build script
chmod +x build.sh
./build.sh

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

## Upstream Source

- **Patches from**: [mkopec/linux hdmi_frl_amd_staging](https://github.com/mkopec/linux/tree/hdmi_frl_amd_staging)
- **Authors**: Michal Kopec, Tomasz Pakula

## License

The patches are licensed under GPL-2.0, matching the Linux kernel license.
