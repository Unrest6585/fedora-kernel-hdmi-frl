#!/bin/bash
# Build script for patched Fedora kernel with HDMI FRL support
# Downloads kernel SRPM from Koji, applies FRL patch, builds patched SRPM
set -euo pipefail

FEDORA_VERSION="${FEDORA_VERSION:-43}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
PATCHES_DIR="${SCRIPT_DIR}/patches"

echo "==> Setting up build environment..."
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# Find the newest kernel NVR across Koji tags
echo "==> Looking up latest kernel NVR for f${FEDORA_VERSION}..."
NVR=""
for tag in "f${FEDORA_VERSION}-updates" "f${FEDORA_VERSION}-updates-candidate" "f${FEDORA_VERSION}"; do
    TAG_NVR=$(koji list-tagged --latest "${tag}" kernel 2>/dev/null \
        | awk 'NR>2 && /^kernel-/{print $1; exit}')
    if [ -n "${TAG_NVR}" ]; then
        echo "    Found in tag ${tag}: ${TAG_NVR}"
        # Keep the highest version across all tags (exit 11 = first is newer)
        if [ -z "${NVR}" ] || { rc=0; rpmdev-vercmp "${TAG_NVR}" "${NVR}" &>/dev/null || rc=$?; [ "$rc" -eq 11 ]; }; then
            NVR="${TAG_NVR}"
        fi
    fi
done

if [ -z "${NVR}" ]; then
    echo "Error: Could not determine kernel NVR from Koji"
    exit 1
fi
echo "==> Using newest: ${NVR}"

# Download the SRPM from Koji
SRPM="${NVR}.src.rpm"
if [ ! -f "${SRPM}" ]; then
    echo "==> Downloading ${SRPM} from Koji..."
    koji download-build --arch=src "${NVR}"
else
    echo "==> Using cached ${SRPM}"
fi

echo "==> Extracting SRPM..."
rpm2cpio "${SRPM}" | cpio -idmv

# Copy patches
echo "==> Copying HDMI FRL patches..."
cp "${PATCHES_DIR}"/*.patch .

# Modify the spec file to include our patches
echo "==> Modifying kernel.spec..."

PATCH_NUM=1000000
for patch in "${PATCHES_DIR}"/*.patch; do
    pname=$(basename "${patch}")

    # Add patch definition before END OF PATCH DEFINITIONS marker
    if ! grep -qF "Patch${PATCH_NUM}: ${pname}" kernel.spec; then
        sed -i "/^# END OF PATCH DEFINITIONS/i\\Patch${PATCH_NUM}: ${pname}" kernel.spec
    fi

    # Add patch application before END OF PATCH APPLICATIONS marker
    if ! grep -qF "ApplyOptionalPatch ${pname}" kernel.spec; then
        sed -i "/^# END OF PATCH APPLICATIONS/i\\ApplyOptionalPatch ${pname}" kernel.spec
    fi

    PATCH_NUM=$((PATCH_NUM + 1))
done

# Append .hdmi.frl to the specrelease (before %{?buildid}%{?dist})
sed -i 's/^%define specrelease \(.*\)\(%{?buildid}%{?dist}\)/%define specrelease \1.hdmi.frl\2/' kernel.spec

echo "==> Building SRPM..."
rpmbuild -bs kernel.spec \
    --define "_sourcedir ${BUILD_DIR}" \
    --define "_srcrpmdir ${BUILD_DIR}"

NEW_SRPM=$(ls -1t kernel-*.hdmi.frl*.src.rpm | head -1)
echo "==> Created: ${NEW_SRPM}"
mv "${NEW_SRPM}" "${SCRIPT_DIR}/"

echo "==> Done! SRPM ready for COPR upload: ${SCRIPT_DIR}/${NEW_SRPM}"
