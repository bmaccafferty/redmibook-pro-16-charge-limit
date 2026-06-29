#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"
CONFIG_DIR="${HOME}/.config/redmibook-pro-16-charge-limit"

echo "=== Battery Charge Limit — Install ==="

# --- 1. acpi_call kernel module ---
echo "[1/6] Cloning acpi_call source for auto-rebuild..."
sudo mkdir -p /var/lib/redmibook-pro-16-charge-limit
if [ ! -d /var/lib/redmibook-pro-16-charge-limit/acpi_call_src ]; then
    sudo git clone --depth=1 https://github.com/nix-community/acpi_call.git /var/lib/redmibook-pro-16-charge-limit/acpi_call_src
    echo "  ✓ Source cached at /var/lib/redmibook-pro-16-charge-limit/acpi_call_src"
else
    echo "  ✓ Source already cached"
fi

echo "  Installing rebuild script..."
sudo cp "${REPO_DIR}/bin/rebuild-acpi-call.sh" /var/lib/redmibook-pro-16-charge-limit/
sudo chmod +x /var/lib/redmibook-pro-16-charge-limit/rebuild-acpi-call.sh
echo "  ✓ rebuild-acpi-call.sh"

# Install module load system service
sudo cp "${REPO_DIR}/systemd/acpi-call-load.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable acpi-call-load.service
sudo systemctl start acpi-call-load.service || true
echo "  ✓ acpi-call-load.service installed & started"

# --- 2. Backend script ---
echo "[2/6] Installing backend script..."
mkdir -p "${BIN_DIR}"
cp "${REPO_DIR}/bin/redmibook-pro-16-charge-limit" "${BIN_DIR}/redmibook-pro-16-charge-limit"
chmod +x "${BIN_DIR}/redmibook-pro-16-charge-limit"
echo "  ✓ ${BIN_DIR}/redmibook-pro-16-charge-limit"

# --- 3. Sudoers rule ---
echo "[3/6] Installing sudoers rule (NOPASSWD)..."
sudo cp "${REPO_DIR}/sudoers.d/redmibook-pro-16-charge-limit" /etc/sudoers.d/
sudo chmod 440 /etc/sudoers.d/redmibook-pro-16-charge-limit
sudo visudo -c -f /etc/sudoers.d/redmibook-pro-16-charge-limit
echo "  ✓ /etc/sudoers.d/redmibook-pro-16-charge-limit"

# --- 4. GTK4 GUI ---
echo "[4/6] Installing GUI..."
cp "${REPO_DIR}/bin/redmibook-pro-16-charge-limit-gui" "${BIN_DIR}/redmibook-pro-16-charge-limit-gui"
chmod +x "${BIN_DIR}/redmibook-pro-16-charge-limit-gui"

# Desktop file
mkdir -p "${HOME}/.local/share/applications"
cp "${REPO_DIR}/redmibook-pro-16-charge-limit.desktop" "${HOME}/.local/share/applications/" 2>/dev/null || cat > "${HOME}/.local/share/applications/redmibook-pro-16-charge-limit.desktop" << EOF
[Desktop Entry]
Type=Application
Name=RedmiBook Pro 16 Charge Limit
Comment=Set charge limit for Xiaomi RedmiBook Pro 16
Exec=${BIN_DIR}/redmibook-pro-16-charge-limit-gui
Icon=battery
Terminal=false
Categories=Settings;X-Hardware;
StartupNotify=true
EOF
echo "  ✓ GUI + desktop entry"

# --- 5. Config dir + systemd user service ---
echo "[5/6] Installing systemd user service (boot restore)..."
mkdir -p "${SYSTEMD_USER_DIR}"
cp "${REPO_DIR}/systemd/redmibook-pro-16-charge-limit-restore.service" "${SYSTEMD_USER_DIR}/"
mkdir -p "${CONFIG_DIR}"
systemctl --user daemon-reload
systemctl --user enable redmibook-pro-16-charge-limit-restore.service
systemctl --user restart redmibook-pro-16-charge-limit-restore.service
echo "  ✓ redmibook-pro-16-charge-limit-restore.service enabled"

# --- 6. Clean up stale module (if kernel changed) ---
echo "[6/6] Checking kernel module compatibility..."
if lsmod | grep -q acpi_call; then
    echo "  ✓ Module already loaded"
else
    echo "  Will rebuild on next boot via acpi-call-load.service"
fi

echo ""
echo "=== Install complete ==="
echo "  GUI:   redmibook-pro-16-charge-limit-gui"
echo "  CLI:   sudo redmibook-pro-16-charge-limit set 80"
echo "  Log:   journalctl --user -u redmibook-pro-16-charge-limit-restore.service"
