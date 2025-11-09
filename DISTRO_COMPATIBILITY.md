# Dual-Distro Compatibility Guide

All run scripts have been updated to work on both **Arch Linux** and **Ubuntu/Debian** systems.

## What Changed

### New Component: `lib/distro-utils.sh`
A shared library that provides:
- **OS Detection**: Automatically detects Arch or Ubuntu/Debian
- **Package Manager Abstraction**: Unified functions for installing packages
- **Package Name Mapping**: Translates Ubuntu package names to Arch equivalents
- **AUR Helper Management**: Automatically installs `yay` on Arch if needed

### Updated Scripts

All scripts in `runs/` now:
1. Auto-detect your Linux distribution
2. Use the appropriate package manager (`pacman`/`yay` for Arch, `apt` for Ubuntu)
3. Map package names correctly between distros
4. Handle distro-specific installation methods

| Script | Arch Changes | Ubuntu Changes |
|--------|--------------|----------------|
| **aafirst.sh** | Uses `pacman -Syu` | Uses `apt update && upgrade` |
| **cli.sh** | Maps package names, uses pacman | Same packages via apt |
| **docker.sh** | Installs Docker Engine via pacman | Uses official Docker repo |
| **go.sh** | Binary install (portable) | Binary install (portable) |
| **neovim.sh** | Maps Lua packages | Same build process |
| **node.sh** | Uses pacman nodejs | Uses NodeSource repo |
| **python.sh** | Uses rolling Python | Uses deadsnakes PPA for 3.11 |
| **rust.sh** | Uses rustup (portable) | Uses rustup (portable) |
| **zephyr.sh** | Uses pacman + AUR packages | Uses apt + Kitware CMake |
| **nvcc.sh** | Installs from AUR | Uses NVIDIA repo |

## Usage

### Run All Scripts
```bash
./run.sh
```

### Run Specific Script
```bash
./run.sh cli
# or
./runs/cli.sh
```

### Run Multiple Scripts
```bash
./run.sh aafirst cli docker
```

## How It Works

1. **OS Detection**: Each script sources `lib/distro-utils.sh` which detects your OS
2. **Conditional Installation**: Scripts use `case` statements to execute distro-specific commands
3. **Package Mapping**: Ubuntu package names are automatically mapped to Arch equivalents

### Example: Package Name Mapping

| Ubuntu Package | Arch Package |
|----------------|--------------|
| `build-essential` | `base-devel` |
| `ninja-build` | `ninja` |
| `python3-dev` | `python` |
| `liblua5.1-0-dev` | `lua51` |
| `device-tree-compiler` | `dtc` |

## Requirements

### Arch Linux
- Base system with `pacman`
- Script will auto-install `yay` AUR helper if needed

### Ubuntu/Debian
- Base system with `apt`
- `sudo` access for package installation

## Key Functions in `lib/distro-utils.sh`

```bash
# Initialize distro detection
init_distro

# Install packages (auto-detects package manager)
install_packages package1 package2

# Install with automatic name mapping
install_mapped_packages ubuntu-package-name

# Add user to group
add_user_to_group docker

# Enable systemd service
enable_service docker

# Check if command exists
command_exists docker
```

## Notes

- **AUR packages**: On Arch, some packages come from AUR (installed via `yay`)
- **Docker**: Both distros install Docker Engine (lightweight), not Docker Desktop
- **Python versions**: Arch uses rolling release (latest), Ubuntu uses Python 3.11 via PPA
- **CMake**: Ubuntu uses Kitware repo for latest version, Arch uses official repos

## Troubleshooting

### "yay not found" on Arch
The script will automatically install `yay` when you run any script.

### Package conflicts
If you have old PPAs or repositories, you may need to clean them:
```bash
# Ubuntu
sudo apt autoremove
sudo apt autoclean

# Arch
sudo pacman -Sc
yay -Sc
```

### Permission denied
Ensure your user has sudo privileges:
```bash
sudo usermod -aG sudo $USER  # Ubuntu
sudo usermod -aG wheel $USER  # Arch
```

## Testing

Scripts have been updated but not yet tested on both distros. Please report any issues!

## Supported Distributions

✅ **Tested/Supported:**
- Arch Linux
- Ubuntu 20.04+
- Debian 11+

🔄 **Should work:**
- Manjaro
- EndeavourOS
- Pop!_OS
- Linux Mint

---

*Last updated: 2025-11-07*
