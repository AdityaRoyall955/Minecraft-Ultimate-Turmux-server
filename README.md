# Minecraft Panel Pro 🔥

A Termux-optimized Minecraft server management panel.

## Features ✨

- **Auto Java Install** - Automatically installs OpenJDK 21
- **PaperMC/Purpur Support** - Choose your server software
- **Plugin Auto-Download** - Geyser + Floodgate for Bedrock players
- **Termux Launcher** - Simple `mc` command from anywhere
- **Server Auto-Download** - Fetches latest server jar automatically

## Install 📥

```bash
git clone https://github.com/AdityaRoyall955/Minecraft-Ultimate-Turmux-server.git
cd Minecraft-Ultimate-Turmux-server
bash install.sh
```

## Usage 🚀

```bash
mc -s setup     # Install Java & dependencies
mc -s plugins   # Download plugins
mc -s start     # Start server
mc -s restart   # Restart server
mc -s stop      # Stop server
mc -s update    # Update server jar
mc -s status    # Check status
mc -s delete    # Delete world (CAREFUL!)
```

## Configuration ⚙️

Edit `~/minecraft-server/core/server.conf`:

```bash
SERVER_RAM=2000M
MIN_RAM=1000M
SERVER_TYPE=Paper
MC_VERSION=1.20.4
```

## Requirements 📋

- Termux (Android)
- ~2GB free storage
- ~2GB RAM recommended

Made with 💜 for Minecraft server admins!
