# Minecraft Panel Pro 🔥

A Termux-optimized Minecraft server management panel supporting both **Java** (Paper/Purpur) and **Bedrock** (PowerNukkitX) editions!

## Features ✨

- **🎮 Multi-Edition Support** - Java (Paper/Purpur) AND Bedrock (PowerNukkitX)
- **📋 Software Selector** - Interactive menu to choose your server type
- **⚡ Auto Java Install** - Automatically installs OpenJDK 21
- **🔌 Plugin Auto-Download** - Geyser + Floodgate for Java crossplay
- **📱 Termux Launcher** - Simple `mc` command from anywhere
- **⬇️ Auto-Download** - Fetches server jars automatically
- **🔄 Daily Auto-Updates** - Repository auto-updates when new versions release!

## Install 📥

```bash
git clone https://github.com/AdityaRoyall955/Minecraft-Ultimate-Turmux-server.git
cd Minecraft-Ultimate-Turmux-server
bash install.sh
```

## Setup 🚀

```bash
mc -s setup
```

This will show a menu:
```
╔════════════════════════════════════════════════╗
║         SELECT MINECRAFT SERVER SOFTWARE       ║
╠════════════════════════════════════════════════╣
║  [1] PaperMC     - Java Edition (Recommended) ║
║  [2] Purpur      - Java Edition (Fork)        ║
║  [3] PowerNukkitX - Bedrock Edition           ║
╚════════════════════════════════════════════════╝
```

## Usage 🎮

```bash
mc -s setup      # Select software & install dependencies
mc -s start      # Start server
mc -s restart    # Restart server
mc -s stop       # Stop server
mc -s update     # Update server jar
mc -s status     # Check status
mc -s delete     # Delete world (CAREFUL!)
mc -s software   # Change server software

# Java only:
mc -s plugins    # Download Geyser + Floodgate
```

## 🔄 Daily Auto-Update System

This repository automatically checks for updates **daily at 00:00 UTC**!

### What gets updated?
- ✅ **PaperMC** - Latest builds from PaperMC API
- ✅ **Purpur** - Latest builds from PurpurMC API
- ✅ **PowerNukkitX** - Latest releases from GitHub

### How it works:
1. GitHub Actions runs daily via cron schedule
2. Checks each server software's API for new versions
3. Compares with `versions/*.version` files
4. Updates download URLs in `menu.sh` automatically
5. Commits and pushes changes to repository

### Manual Update Check:
```bash
bash scripts/check_updates.sh
```

### Version Tracking:
Current versions are tracked in:
- `versions/paper.version`
- `versions/purpur.version`
- `versions/powernukkitx.version`

## Server Types 📋

| Type | Edition | Description |
|------|---------|-------------|
| **PaperMC** | Java | High performance, plugin support |
| **Purpur** | Java | Paper fork with extra features |
| **PowerNukkitX** | Bedrock | Minecraft Bedrock for Termux |

## Ports 🔌

- **Java (Paper/Purpur)**: 25565
- **Bedrock (PowerNukkitX)**: 19132

## Requirements 📋

- Termux (Android)
- ~2GB free storage
- ~2GB RAM recommended

## Troubleshooting 🔧

**Can't connect?**
- Java: Check port 25565 is open
- Bedrock: Check port 19132 is open

**Out of memory?**
Lower RAM in `core/server.conf`

**Want latest server version?**
Run `mc -s update` or wait for daily auto-update!

Made with 💜 for Minecraft server admins!
