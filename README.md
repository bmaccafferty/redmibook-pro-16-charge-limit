# Battery Charge Limit — Xiaomi RedmiBook Pro 16

GTK4 GUI + CLI tool for setting the battery charge limit on the Xiaomi RedmiBook Pro 16 (2025) via ACPI calls. Works on Bazzite/Kinoite (atomic Fedora) and standard Linux.

```bash
sudo battery-charge-limit set 80    # limit to 80%
sudo battery-charge-limit disable   # charge to full
sudo battery-charge-limit get       # read current limit
```

Available limits: **40%, 50%, 60%, 70%, 80%**

## Requirements

- Linux with `acpi_call` kernel module
- Python 3 + PyGObject (GTK4) for the GUI
- `sudo` access

## Quick Install

```bash
# 1. Build & install the acpi_call kernel module
git clone https://github.com/nix-community/acpi_call.git
cd acpi_call && make && sudo insmod acpi_call.ko
sudo mkdir -p /var/lib/battery-charge-limit
sudo cp acpi_call.ko /var/lib/battery-charge-limit/

# 2. Run install script
./install.sh
```

Or install manually — see [Installation](#installation) below.

## GUI

Launch from your app menu ("Battery Charge Limit") or run:

```bash
battery-charge-limit-gui
```

## How It Works

The device's firmware supports charge limiting via ACPI methods `0xFB` and `0xFA` on the `WMID.WMAA` device. This tool wraps those calls:

1. **Backend** (`bin/battery-charge-limit`) — writes ACPI commands to `/proc/acpi/call`
2. **GTK4 GUI** (`bin/battery-charge-limit-gui`) — Python/PyGObject radio button interface
3. **Boot restore** — systemd user service re-applies the last saved limit after login

### Architecture

```
┌────────────────────────────────────────┐
│  GTK4 GUI (user)                       │
│  runs: sudo battery-charge-limit set X │
└──────────────────┬─────────────────────┘
                   │ sudo (NOPASSWD)
┌──────────────────▼─────────────────────┐
│  battery-charge-limit (root)           │
│  writes ACPI methods 0xFB / 0xFA      │
└──────────────────┬─────────────────────┘
                   │
┌──────────────────▼─────────────────────┐
│  /proc/acpi/call ← acpi_call.ko       │
└────────────────────────────────────────┘
```

## Installation

### 1. Kernel Module

The `acpi_call` kernel module is **not** in standard repos. Build from source:

```bash
git clone https://github.com/nix-community/acpi_call.git
cd acpi_call
make
sudo mkdir -p /var/lib/battery-charge-limit
sudo cp acpi_call.ko /var/lib/battery-charge-limit/
```

### 2. Script

```bash
cp bin/battery-charge-limit ~/.local/bin/
chmod +x ~/.local/bin/battery-charge-limit
```

### 3. Sudoers (passwordless)

```bash
sudo cp sudoers.d/battery-charge-limit /etc/sudoers.d/
sudo chmod 440 /etc/sudoers.d/battery-charge-limit
```

### 4. GUI (optional)

```bash
cp bin/battery-charge-limit-gui ~/.local/bin/
chmod +x ~/.local/bin/battery-charge-limit-gui
```

### 5. Boot Restore (optional)

```bash
cp systemd/battery-charge-limit-restore.service ~/.config/systemd/user/
systemctl --user enable battery-charge-limit-restore.service
```

### 6. Kernel Module Auto-Load & Rebuild (optional)

The module is loaded at boot via `acpi-call-load.service`. If the kernel updates
(common on atomic Fedora), the service automatically rebuilds the module from
cached source — no manual intervention needed.

```bash
sudo cp systemd/acpi-call-load.service /etc/systemd/system/
sudo systemctl enable acpi-call-load.service
```

Requires `kernel-devel` for the running kernel (pre-installed on Bazzite).

## Files

| Path | Purpose |
|---|---|---|
| `bin/battery-charge-limit` | Backend CLI — set/get/disable/restore |
| `bin/battery-charge-limit-gui` | GTK4 GUI app |
| `bin/rebuild-acpi-call.sh` | Auto-rebuild script for kernel updates |
| `systemd/acpi-call-load.service` | Loads kernel module at boot (rebuilds if needed) |
| `systemd/battery-charge-limit-restore.service` | Restores limit after login |
| `sudoers.d/battery-charge-limit` | NOPASSWD rule for the backend |
| `install.sh` | Automated install |

## License

MIT
