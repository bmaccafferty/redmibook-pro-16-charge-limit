#!/bin/bash
# Rebuild and load acpi_call kernel module for the current kernel.
#
# Designed for atomic Fedora (Bazzite/Silverblue/Kinoite) where kernel
# updates happen via image updates and /lib/modules is read-only.
# The module is rebuilt from cached source when the kernel changes.
#
# Called by: acpi-call-load.service

set -euo pipefail

SRC_DIR="/var/lib/redmibook-pro-16-charge-limit/acpi_call_src"
MODULE_OUT="/tmp/acpi_call.ko"
MODULE_DEST="/var/lib/redmibook-pro-16-charge-limit/acpi_call.ko"

# 1. Already loaded?
if lsmod | grep -q acpi_call; then
    echo "acpi_call already loaded"
    exit 0
fi

# 2. Try existing module
if [ -f "$MODULE_DEST" ]; then
    if insmod "$MODULE_DEST" 2>/dev/null; then
        echo "Loaded existing module $(ls -la "$MODULE_DEST" | awk '{print $5, $6, $7}')"
        exit 0
    fi
    echo "Existing module incompatible with kernel $(uname -r)"
fi

# 3. Rebuild from cached source
if [ ! -d "$SRC_DIR" ]; then
    echo "ERROR: Source not found at $SRC_DIR"
    echo "Clone it: git clone https://github.com/nix-community/acpi_call.git $SRC_DIR"
    exit 1
fi

KERNEL_DEVEL="/lib/modules/$(uname -r)/build"
if [ ! -d "$KERNEL_DEVEL" ]; then
    echo "ERROR: kernel-devel not found for $(uname -r)"
    echo "Install it: sudo rpm-ostree install kernel-devel-$(uname -r)"
    exit 1
fi

echo "Rebuilding acpi_call for kernel $(uname -r)..."
cd "$SRC_DIR"
make clean 2>/dev/null || true
make -j"$(nproc)" 2>&1
cp acpi_call.ko "$MODULE_DEST"
cp acpi_call.ko "$MODULE_OUT"  # also leave in /tmp for reference

insmod "$MODULE_DEST"
echo "Module built and loaded OK"
