# Minecraft Panel Pro 🔥

A Termux-optimized Minecraft server management panel supporting common **Java** server software and **Bedrock** (PowerNukkitX).

**🎮 Now supporting Minecraft 1.26.x (2026 Edition)!**

## Features ✨

- **🎮 Multi-Edition Support** - Java (Paper/Purpur) AND Bedrock (PowerNukkitX)
- **📋 Software Selector** - Interactive menu to choose your server type
- **⚡ Auto Java Install** - Automatically installs OpenJDK 21
- **🔌 Plugin Auto-Download** - Geyser + Floodgate for Java crossplay
- **📱 Termux Launcher** - Simple `mc` command from anywhere
- **⬇️ Auto-Download** - Fetches server jars automatically
- **🔄 Daily Auto-Updates** - Repository auto-updates when new versions release!
- **☁️ Repo Sync** - Check GitHub repo for latest versions and auto-update!
- **📦 Auto-Detect** - Automatically detects latest Minecraft version from Paper/Purpur APIs!
- **🆕 Auto-Version** - No hardcoded versions! Always gets latest from APIs!

![Minecraft Version](https://shields.io)
![Platform](https://shields.io)
![License](https://shields.io)


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
║  [3] Folia       - Java Edition (Threads)     ║
║  [4] Vanilla     - Official Java Edition     ║
║  [5] Fabric      - Java Edition (Mods)        ║
║  [6] Spigot      - Java Edition (BuildTools)  ║
║  [7] PowerNukkitX - Bedrock Edition           ║
╚════════════════════════════════════════════════╝
```

## Usage 🎮

```bash
mc -s setup      # Select software & install dependencies
mc -s start      # Start server (shows version info!)
mc -s restart    # Restart server
mc -s stop       # Stop server
mc -s check      # Check if new version available in repo
mc -s update     # Update server jar from repo
mc -s status     # Check status + current version
mc -s delete     # Delete world (CAREFUL!)
mc -s software   # Change server software

# Local browser manager:
mc -s manager     # Open Mods and Plugins manager
mc -s mods       # Open Mods manager
mc -s plugins    # Open Plugins manager
```

The local manager also supports:

- Modrinth search and one-click mod/plugin installation
- CurseForge search and one-click mod/plugin installation
- Modrinth `.mrpack` import with required files and overrides
- Custom software JAR download with custom version selection
- Web Settings for menu title and accent color customization
- Refreshing local files without restarting the server

CurseForge requires a personal API key. Open `mc -s manager`, enter the key in
**Settings**, and save it. The key is stored only in the local
`core/manager-settings.json` file and is not shown back in the browser.

Custom software is saved as `server.jar` and becomes the selected software the
next time the `mc` menu is opened.

## 🔄 Update System

### For Users: Check & Update from Repo

**Check for updates:**
```bash
mc -s check
```
Output:
```
🔍 Checking AdityaRoyall955/Minecraft-Ultimate-Turmux-server for updates...

📱 Local version:  1.26.2-112
📦 Repo version:   1.26.2-145

🎉 New version available!
```

**Update to latest:**
```bash
mc -s update
```
Output:
```
🔄 Checking PaperMC for updates...

📱 Current version:  1.26.2-112
📦 Latest version:   1.26.2-145

📥 Downloading update...
💾 Backing up current jar...
✅ PaperMC updated to 1.26.2-145!

🚀 Run 'mc -s start' to use the new version
```

**Start with new version:**
```bash
mc -s start
```
The server will now use the updated version!

### 🔄 Daily Auto-Update (Repository)

This repository automatically checks for updates **daily at 00:00 UTC**!

When new versions are released:
1. GitHub Actions detects the new version
2. Updates `versions/*.version` files
3. Updates download URLs in `menu.sh`
4. Users run `mc -s update` to get the new version

### Version Tracking:
- **Repo versions**: `versions/*.version` files in GitHub repo
- **Local versions**: `~/minecraft-server/versions/*.version` on your device

## Server Types 📋

| Type | Edition | Description |
|------|---------|-------------|
| **PaperMC** | Java | High performance, plugin support (1.26.x) |
| **Purpur** | Java | Paper fork with extra features |
| **Folia** | Java | Regionised multithreaded Paper fork |
| **Vanilla** | Java | Official Mojang server |
| **Fabric** | Java | Lightweight mod-loader server |
| **Spigot** | Java | BuildTools-based plugin server |
| **PowerNukkitX** | Bedrock | Minecraft Bedrock for Termux |

## Ports 🔌

- **Java (Paper/Purpur)**: 25565
- **Bedrock (PowerNukkitX)**: 19132

## Requirements 📋

- Termux (Android)
- ~2GB free storage
- ~2GB RAM recommended

## 🆕 Minecraft 2026 (1.26.x)

This panel supports the **Minecraft 2026** update:
- **New format**: `1.26.x` (Minecraft 2026)
- **PaperMC**: 1.26.2 with latest builds
- **Purpur**: 1.26.2 with latest builds
- **Download**: `paper-1.26.2-xxx.jar`
- **Official**: https://minecraft.net

## Troubleshooting 🔧

**Can't connect?**
- Java: Check port 25565 is open
- Bedrock: Check port 19132 is open

**Out of memory?**
Lower RAM in `core/server.conf`

**Want latest server version?**
```bash
mc -s check    # See if update available
mc -s update   # Download latest from repo
mc -s start    # Start with new version!
```

**Update not working?**
Make sure you have internet connection and the repo is accessible.

---

**© 2026 - Minecraft Panel Pro**  
Made with 💜 for Minecraft server admins!
