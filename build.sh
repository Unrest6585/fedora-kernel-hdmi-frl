#!/bin/bash
# Build script for patched Fedora kernel with HDMI FRL support
set -euo pipefail

FEDORA_VERSION="${FEDORA_VERSION:-43}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
PATCHES_DIR="${SCRIPT_DIR}/patches"

echo "==> Setting up build environment..."
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# Get the latest kernel version from Fedora
echo "==> Fetching latest kernel SRPM for Fedora ${FEDORA_VERSION}..."
KERNEL_NVR=$(dnf repoquery --disablerepo='*' --enablerepo=fedora,updates --releasever="${FEDORA_VERSION}" \
    --qf '%{name}-%{version}-%{release}' kernel 2>/dev/null | sort -V | tail -1)

if [ -z "${KERNEL_NVR}" ]; then
    echo "Error: Could not determine kernel version"
    exit 1
fi

echo "==> Found kernel: ${KERNEL_NVR}"

# Download the SRPM
echo "==> Downloading kernel SRPM..."
dnf download --source --disablerepo='*' --enablerepo=fedora,updates \
    --releasever="${FEDORA_VERSION}" kernel

SRPM=$(ls -1 kernel-*.src.rpm | head -1)
echo "==> Downloaded: ${SRPM}"

# Extract SRPM
echo "==> Extracting SRPM..."
rpm2cpio "${SRPM}" | cpio -idmv

# Copy patches
echo "==> Copying HDMI FRL patches..."
cp "${PATCHES_DIR}"/*.patch .

# Modify the spec file to include our patches
echo "==> Modifying kernel.spec..."

# Get the last patch number
LAST_PATCH=$(grep -E "^Patch[0-9]+:" kernel.spec | tail -1 | sed 's/Patch\([0-9]*\):.*/\1/')
NEXT_PATCH=$((LAST_PATCH + 1))

# Add patch definitions after the last existing patch
PATCH_DEFS=""
PATCH_APPLIES=""
for patch in "${PATCHES_DIR}"/*.patch; do
    pname=$(basename "${patch}")
    PATCH_DEFS="${PATCH_DEFS}Patch${NEXT_PATCH}: ${pname}\n"
    PATCH_APPLIES="${PATCH_APPLIES}ApplyOptionalPatch ${pname}\n"
    NEXT_PATCH=$((NEXT_PATCH + 1))
done

# Insert patch definitions
sed -i "/^Patch${LAST_PATCH}:/a\\
${PATCH_DEFS}" kernel.spec

# Find where patches are applied and add ours
# The Fedora kernel spec uses ApplyOptionalPatch function
sed -i "/^# END OF PATCH APPLICATIONS/i\\
# HDMI FRL patches\\
${PATCH_APPLIES}" kernel.spec

# Update the release tag to indicate this is a custom build
sed -i 's/^%define specrelease.*/%define specrelease 1.hdmi.frl/' kernel.spec

echo "==> Building SRPM..."
rpmbuild -bs kernel.spec \
    --define "_sourcedir ${BUILD_DIR}" \
    --define "_srcrpmdir ${BUILD_DIR}"

NEW_SRPM=$(ls -1t kernel-*.src.rpm | head -1)
echo "==> Created: ${NEW_SRPM}"
mv "${NEW_SRPM}" "${SCRIPT_DIR}/"

echo "==> Done! SRPM ready for COPR upload: ${SCRIPT_DIR}/${NEW_SRPM}"
