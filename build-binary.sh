#!/bin/bash
# Build binary kernel RPMs from a patched kernel SRPM.
# Skips debug/perf/tools/selftests/signing to cut build time ~60%.
set -euo pipefail

SRPM="${1:-}"
if [ -z "${SRPM}" ] || [ ! -f "${SRPM}" ]; then
    echo "Usage: $0 /path/to/kernel-*.src.rpm"
    echo "Latest available:"
    ls -1t kernel-*.src.rpm 2>/dev/null | head -3
    exit 1
fi

echo "==> Installing build deps for ${SRPM}..."
sudo dnf builddep -y "${SRPM}"

echo "==> Setting up rpmbuild tree..."
rpmdev-setuptree

LOG="${HOME}/kernel-binary-build.log"
echo "==> Building (log: ${LOG})..."
rpmbuild --rebuild "${SRPM}" \
    --without debug \
    --without doc \
    --without perf \
    --without tools \
    --without bpftool \
    --without selftests \
    --without kabichk \
    --without signkernel \
    --without signmodules \
    --with baseonly \
    2>&1 | tee "${LOG}"

echo "==> Output RPMs:"
mapfile -t RPMS < <(
    find ~/rpmbuild/RPMS -type f -name 'kernel-*.rpm' \
        ! -name '*debug*.rpm' \
        ! -name '*debuginfo*.rpm' \
        ! -name '*debugsource*.rpm' \
        -print 2>/dev/null | sort
)

if [ "${#RPMS[@]}" -eq 0 ]; then
    echo "(no RPMs produced - check ${LOG})"
else
    printf '%s\n' "${RPMS[@]}"
fi
