#!/bin/bash
# Build script for patched Fedora kernel with HDMI FRL fixes
# Downloads kernel SRPM from Koji, applies the Linux 7.2 FRL patches, builds patched SRPM
set -euo pipefail

FEDORA_VERSION="${FEDORA_VERSION:-44}"
KERNEL_NVR="${KERNEL_NVR:-}"
MIN_KERNEL_VERSION="7.2.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
PATCHES_DIR="${SCRIPT_DIR}/patches/7.2"

RELEASE_SUFFIX=".hdmi.frl"

echo "==> Setting up build environment..."
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

if [ -n "${KERNEL_NVR}" ]; then
    NVR="${KERNEL_NVR}"
    echo "==> Using pinned kernel NVR: ${NVR}"
else
    # Find the newest stable kernel NVR across Koji tags.
    echo "==> Looking up latest stable kernel NVR for f${FEDORA_VERSION}..."
    NVR=""
    for tag in \
        "f${FEDORA_VERSION}-updates" \
        "f${FEDORA_VERSION}"; do
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
    echo "==> Using newest stable: ${NVR}"
fi

# Linux 7.2 ships AMD HDMI FRL upstream (off by default). The patches in
# patches/7.2 enable it by default and fix FreeSync detection on FRL sinks;
# they target the 7.2 source layout only.
KERNEL_VERSION="${NVR#kernel-}"
KERNEL_VERSION="${KERNEL_VERSION%%-*}"
rc=0
rpmdev-vercmp "${KERNEL_VERSION}" "${MIN_KERNEL_VERSION}" &>/dev/null || rc=$?
if [ "${rc}" -eq 12 ]; then
    echo "Error: Kernel ${KERNEL_VERSION} is older than ${MIN_KERNEL_VERSION}."
    echo "The Linux 7.1 FRL patch was retired; see git history."
    exit 1
fi

# Download the SRPM from Koji
SRPM="${NVR}.src.rpm"
if [ ! -f "${SRPM}" ]; then
    echo "==> Downloading ${SRPM} from Koji..."
    koji download-build --arch=src "${NVR}"
else
    echo "==> Using cached ${SRPM}"
fi

echo "==> Extracting SRPM..."
rpm2cpio "${SRPM}" | cpio -idmvu

# Copy patches
echo "==> Copying HDMI FRL patches for Linux 7.2..."
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

# Append release suffix to the specrelease (before %{?buildid}%{?dist})
sed -i "s/^%define specrelease \(.*\)\(%{?buildid}%{?dist}\)/%define specrelease \1${RELEASE_SUFFIX}\2/" kernel.spec

echo "==> Building SRPM..."
rpmbuild -bs kernel.spec \
    --define "_sourcedir ${BUILD_DIR}" \
    --define "_srcrpmdir ${BUILD_DIR}"

NEW_SRPM=$(ls -1t kernel-*${RELEASE_SUFFIX}*.src.rpm | head -1)
echo "==> Created: ${NEW_SRPM}"
mv "${NEW_SRPM}" "${SCRIPT_DIR}/"

echo "==> Done! SRPM ready for COPR upload: ${SCRIPT_DIR}/${NEW_SRPM}"
