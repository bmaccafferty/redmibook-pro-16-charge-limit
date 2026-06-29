#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"
CONFIG_DIR="${HOME}/.config/battery-charge-limit"

echo "=== Battery Charge Limit — Install ==="

# --- 1. acpi_call kernel module ---
echo "[1/5] Installing acpi_call kernel module..."
if ! lsmod | grep -q acpi_call; then
    if [ -f /var/lib/battery-charge-limit/acpi_call.ko ]; then
        sudo insmod /var/lib/battery-charge-limit/acpi_call.ko
    else
        echo "  WARNING: acpi_call.ko not found at /var/lib/battery-charge-limit/"
        echo "  Build it first: https://github.com/nix-community/acpi_call"
    fi
fi

# Install module load system service
sudo cp "${REPO_DIR}/systemd/acpi-call-load.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable acpi-call-load.service
sudo systemctl start acpi-call-load.service
echo "  ✓ acpi-call-load.service installed & started"

# --- 2. Backend script ---
echo "[2/5] Installing backend script..."
mkdir -p "${BIN_DIR}"
cp "${REPO_DIR}/bin/battery-charge-limit" "${BIN_DIR}/battery-charge-limit"
chmod +x "${BIN_DIR}/battery-charge-limit"
echo "  ✓ ${BIN_DIR}/battery-charge-limit"

# --- 3. Sudoers rule ---
echo "[3/5] Installing sudoers rule (NOPASSWD)..."
sudo cp "${REPO_DIR}/sudoers.d/battery-charge-limit" /etc/sudoers.d/
sudo chmod 440 /etc/sudoers.d/battery-charge-limit
sudo visudo -c -f /etc/sudoers.d/battery-charge-limit
echo "  ✓ /etc/sudoers.d/battery-charge-limit"

# --- 4. GTK4 GUI ---
echo "[4/5] Installing GUI..."
cp "${REPO_DIR}/bin/battery-charge-limit-gui" "${BIN_DIR}/battery-charge-limit-gui"
chmod +x "${BIN_DIR}/battery-charge-limit-gui"

# Desktop file
mkdir -p "${HOME}/.local/share/applications"
cp "${REPO_DIR}/battery-charge-limit.desktop" "${HOME}/.local/share/applications/" 2>/dev/null || cat > "${HOME}/.local/share/applications/battery-charge-limit.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Battery Charge Limit
Comment=Set charge limit for Xiaomi RedmiBook Pro 16
Exec=${BIN_DIR}/battery-charge-limit-gui
Icon=battery
Terminal=false
Categories=Settings;X-Hardware;
StartupNotify=true
EOF
echo "  ✓ GUI + desktop entry"

# --- 5. Config dir + systemd user service ---
echo "[5/5] Installing systemd user service (boot restore)..."
mkdir -p "${SYSTEMD_USER_DIR}"
cp "${REPO_DIR}/systemd/battery-charge-limit-restore.service" "${SYSTEMD_USER_DIR}/"
mkdir -p "${CONFIG_DIR}"
systemctl --user daemon-reload
systemctl --user enable battery-charge-limit-restore.service
systemctl --user restart battery-charge-limit-restore.service
echo "  ✓ battery-charge-limit-restore.service enabled"

echo ""
echo "=== Install complete ==="
echo "  GUI:   battery-charge-limit-gui"
echo "  CLI:   sudo battery-charge-limit set 80"
echo "  Log:   journalctl --user -u battery-charge-limit-restore.service"
