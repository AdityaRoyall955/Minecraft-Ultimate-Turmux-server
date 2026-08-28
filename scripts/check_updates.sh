#!/data/data/com.termux/files/usr/bin/bash

# Daily Update Checker Script for Termux
# Run this with: bash scripts/check_updates.sh
# Or add to crontab for daily checks

NC="\e[0m"
GREEN="\e[1;32m"
CYAN="\e[1;36m"
YELLOW="\e[1;33m"
RED="\e[1;31m"
MAGENTA="\e[1;35m"
WHITE="\e[1;37m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSIONS_DIR="$SCRIPT_DIR/versions"

mkdir -p "$VERSIONS_DIR"

# GitHub Repo URL
REPO_OWNER="AdityaRoyall955"
REPO_NAME="Minecraft-Ultimate-Turmux-server"
REPO_RAW_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main"

echo -e "${CYAN}🔍 Auto-detecting latest versions from APIs...${NC}"
echo ""

UPDATES_FOUND=false

# ==================== PaperMC Check ====================
echo -e "${CYAN}📋 Checking PaperMC...${NC}"

# Auto-detect latest from API
PAPER_LATEST_VER=$(curl -s "https://api.papermc.io/v2/projects/paper" | grep -o '"[0-9]\+\.[0-9]\+\.[0-9]\+"' | tr -d '"' | tail -1)
PAPER_LATEST_BUILD=$(curl -s "https://api.papermc.io/v2/projects/paper/versions/${PAPER_LATEST_VER}/builds" | grep -o '"build":[0-9]*' | grep -o '[0-9]*' | tail -1)
PAPER_LATEST="${PAPER_LATEST_VER}-${PAPER_LATEST_BUILD}"

if [[ -z "$PAPER_LATEST" ]]; then
    echo -e "${YELLOW}  ⚠️  Could not fetch Paper version from API${NC}"
    PAPER_LATEST="unknown"
fi

# Get current local version
if [ -f "$VERSIONS_DIR/paper.version" ]; then
    PAPER_CURRENT=$(cat "$VERSIONS_DIR/paper.version")
else
    PAPER_CURRENT="none"
fi

echo "  Local:  ${PAPER_CURRENT}"
echo "  Latest: ${PAPER_LATEST}"

if [ "$PAPER_CURRENT" != "$PAPER_LATEST" ] && [ "$PAPER_LATEST" != "unknown" ]; then
    echo -e "  ${GREEN}📥 PaperMC update available!${NC}"
    echo "$PAPER_LATEST" > "$VERSIONS_DIR/paper.version"
    
    # Get the PaperMC download URL
    PAPER_URL="https://api.papermc.io/v2/projects/paper/versions/${PAPER_LATEST_VER}/builds/${PAPER_LATEST_BUILD}/downloads/paper-${PAPER_LATEST_VER}-${PAPER_LATEST_BUILD}.jar"
    
    # Update menu.sh
    sed -i "s|wget -O server.jar \"https://fill-data.papermc.io/.*|wget -O server.jar \"${PAPER_URL}\"|" "$SCRIPT_DIR/menu.sh"
    sed -i "s|wget -O server.jar \"https://api.papermc.io/.*|wget -O server.jar \"${PAPER_URL}\"|" "$SCRIPT_DIR/menu.sh"
    
    UPDATES_FOUND=true
else
    echo -e "  ${GREEN}✓ PaperMC is up to date${NC}"
fi

echo ""

# ==================== Purpur Check ====================
echo -e "${CYAN}📋 Checking Purpur...${NC}"

# Auto-detect latest from API
PURPUR_LATEST_VER=$(curl -s "https://api.purpurmc.org/v2/purpur" | grep -o '"[0-9]\+\.[0-9]\+\.[0-9]\+"' | tr -d '"' | tail -1)
PURPUR_LATEST_BUILD=$(curl -s "https://api.purpurmc.org/v2/purpur/${PURPUR_LATEST_VER}" | grep -o '[0-9]*' | tail -1)
PURPUR_LATEST="${PURPUR_LATEST_VER}-${PURPUR_LATEST_BUILD}"

if [[ -z "$PURPUR_LATEST" ]]; then
    echo -e "${YELLOW}  ⚠️  Could not fetch Purpur version from API${NC}"
    PURPUR_LATEST="unknown"
fi

# Get current local version
if [ -f "$VERSIONS_DIR/purpur.version" ]; then
    PURPUR_CURRENT=$(cat "$VERSIONS_DIR/purpur.version")
else
    PURPUR_CURRENT="none"
fi

echo "  Local:  ${PURPUR_CURRENT}"
echo "  Latest: ${PURPUR_LATEST}"

if [ "$PURPUR_CURRENT" != "$PURPUR_LATEST" ] && [ "$PURPUR_LATEST" != "unknown" ]; then
    echo -e "  ${GREEN}📥 Purpur update available!${NC}"
    echo "$PURPUR_LATEST" > "$VERSIONS_DIR/purpur.version"
    
    # Get download URL
    PURPUR_URL="https://api.purpurmc.org/v2/purpur/${PURPUR_LATEST_VER}/${PURPUR_LATEST_BUILD}/download"
    
    # Update menu.sh
    sed -i "s|wget -O server.jar \"https://api.purpurmc.org/v2/purpur/.*|wget -O server.jar \"${PURPUR_URL}\"|" "$SCRIPT_DIR/menu.sh"
    
    UPDATES_FOUND=true
else
    echo -e "  ${GREEN}✓ Purpur is up to date${NC}"
fi

echo ""

# ==================== PowerNukkitX Check ====================
echo -e "${MAGENTA}📋 Checking PowerNukkitX...${NC}"

# Auto-detect latest from GitHub
PNX_LATEST=$(curl -s "https://api.github.com/repos/PowerNukkitX/PowerNukkitX/releases/latest" | grep -o '"tag_name":"[^"]*"' | cut -d'"' -f4)

if [[ -z "$PNX_LATEST" ]]; then
    echo -e "${YELLOW}  ⚠️  Could not fetch PowerNukkitX version from GitHub${NC}"
    PNX_LATEST="unknown"
fi

# Get current local version
if [ -f "$VERSIONS_DIR/powernukkitx.version" ]; then
    PNX_CURRENT=$(cat "$VERSIONS_DIR/powernukkitx.version")
else
    PNX_CURRENT="none"
fi

echo "  Local:  ${PNX_CURRENT}"
echo "  Latest: ${PNX_LATEST}"

if [ "$PNX_CURRENT" != "$PNX_LATEST" ] && [ "$PNX_LATEST" != "unknown" ]; then
    echo -e "  ${GREEN}📥 PowerNukkitX update available!${NC}"
    echo "$PNX_LATEST" > "$VERSIONS_DIR/powernukkitx.version"
    
    # Get download URL
    PNX_URL="https://github.com/PowerNukkitX/PowerNukkitX/releases/download/${PNX_LATEST}/powernukkitx.jar"
    
    # Update menu.sh
    sed -i "s|wget -O powernukkitx.jar \"https://github.com/PowerNukkitX/.*|wget -O powernukkitx.jar \"${PNX_URL}\"|" "$SCRIPT_DIR/menu.sh"
    
    UPDATES_FOUND=true
else
    echo -e "  ${GREEN}✓ PowerNukkitX is up to date${NC}"
fi

echo ""

# ==================== Summary ====================
if [ "$UPDATES_FOUND" = true ]; then
    echo -e "${GREEN}🎉 Updates found and menu.sh updated!${NC}"
    echo ""
    echo -e "${CYAN}🚀 To apply updates to your server:${NC}"
    echo "  mc -s update   # Download new server jar"
    echo "  mc -s start    # Start with new version"
    echo ""
    echo -e "${YELLOW}📤 To push changes to GitHub:${NC}"
    echo "  git add -A"
    echo "  git commit -m \"Auto-update server versions\""
    echo "  git push"
else
    echo -e "${GREEN}✅ All server software is up to date!${NC}"
fi

echo ""
echo -e "${CYAN}📅 Next check: Run this script daily or setup cron job${NC}"
