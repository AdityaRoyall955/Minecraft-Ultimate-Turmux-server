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

echo -e "${CYAN}🔍 Checking GitHub repo for updates...${NC}"
echo -e "${CYAN}📦 Repo: ${REPO_OWNER}/${REPO_NAME}${NC}"
echo ""

UPDATES_FOUND=false

# ==================== PaperMC Check ====================
echo -e "${CYAN}📋 Checking PaperMC...${NC}"

# Get latest from repo
PAPER_REPO=$(curl -s "${REPO_RAW_URL}/versions/paper.version" 2>/dev/null)
if [[ -z "$PAPER_REPO" ]]; then
    echo -e "${YELLOW}  ⚠️  Could not fetch Paper version from repo${NC}"
    PAPER_REPO="unknown"
fi

# Get current local version
if [ -f "$VERSIONS_DIR/paper.version" ]; then
    PAPER_CURRENT=$(cat "$VERSIONS_DIR/paper.version")
else
    PAPER_CURRENT="none"
fi

echo "  Local:  ${PAPER_CURRENT}"
echo "  Repo:   ${PAPER_REPO}"

if [ "$PAPER_CURRENT" != "$PAPER_REPO" ] && [ "$PAPER_REPO" != "unknown" ]; then
    echo -e "  ${GREEN}📥 PaperMC update available!${NC}"
    echo "$PAPER_REPO" > "$VERSIONS_DIR/paper.version"
    
    # Get the PaperMC download URL from API
    PAPER_VERSION=$(echo $PAPER_REPO | cut -d'-' -f1)
    PAPER_BUILD=$(echo $PAPER_REPO | cut -d'-' -f2)
    PAPER_URL="https://api.papermc.io/v2/projects/paper/versions/${PAPER_VERSION}/builds/${PAPER_BUILD}/downloads/paper-${PAPER_VERSION}-${PAPER_BUILD}.jar"
    
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

# Get latest from repo
PURPUR_REPO=$(curl -s "${REPO_RAW_URL}/versions/purpur.version" 2>/dev/null)
if [[ -z "$PURPUR_REPO" ]]; then
    echo -e "${YELLOW}  ⚠️  Could not fetch Purpur version from repo${NC}"
    PURPUR_REPO="unknown"
fi

# Get current local version
if [ -f "$VERSIONS_DIR/purpur.version" ]; then
    PURPUR_CURRENT=$(cat "$VERSIONS_DIR/purpur.version")
else
    PURPUR_CURRENT="none"
fi

echo "  Local:  ${PURPUR_CURRENT}"
echo "  Repo:   ${PURPUR_REPO}"

if [ "$PURPUR_CURRENT" != "$PURPUR_REPO" ] && [ "$PURPUR_REPO" != "unknown" ]; then
    echo -e "  ${GREEN}📥 Purpur update available!${NC}"
    echo "$PURPUR_REPO" > "$VERSIONS_DIR/purpur.version"
    
    # Extract version and build
    PURPUR_VERSION=$(echo $PURPUR_REPO | cut -d'-' -f1)
    PURPUR_BUILD=$(echo $PURPUR_REPO | cut -d'-' -f2)
    PURPUR_URL="https://api.purpurmc.org/v2/purpur/${PURPUR_VERSION}/${PURPUR_BUILD}/download"
    
    # Update menu.sh
    sed -i "s|wget -O server.jar \"https://api.purpurmc.org/v2/purpur/.*|wget -O server.jar \"${PURPUR_URL}\"|" "$SCRIPT_DIR/menu.sh"
    
    UPDATES_FOUND=true
else
    echo -e "  ${GREEN}✓ Purpur is up to date${NC}"
fi

echo ""

# ==================== PowerNukkitX Check ====================
echo -e "${MAGENTA}📋 Checking PowerNukkitX...${NC}"

# Get latest from repo
PNX_REPO=$(curl -s "${REPO_RAW_URL}/versions/powernukkitx.version" 2>/dev/null)
if [[ -z "$PNX_REPO" ]]; then
    echo -e "${YELLOW}  ⚠️  Could not fetch PowerNukkitX version from repo${NC}"
    PNX_REPO="unknown"
fi

# Get current local version
if [ -f "$VERSIONS_DIR/powernukkitx.version" ]; then
    PNX_CURRENT=$(cat "$VERSIONS_DIR/powernukkitx.version")
else
    PNX_CURRENT="none"
fi

echo "  Local:  ${PNX_CURRENT}"
echo "  Repo:   ${PNX_REPO}"

if [ "$PNX_CURRENT" != "$PNX_REPO" ] && [ "$PNX_REPO" != "unknown" ]; then
    echo -e "  ${GREEN}📥 PowerNukkitX update available!${NC}"
    echo "$PNX_REPO" > "$VERSIONS_DIR/powernukkitx.version"
    
    # Get download URL
    PNX_URL="https://github.com/PowerNukkitX/PowerNukkitX/releases/download/${PNX_REPO}/powernukkitx.jar"
    
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
    echo -e "${GREEN}✅ All server software is up to date with repo!${NC}"
fi

echo ""
echo -e "${CYAN}📅 Next check: Run this script daily or setup cron job${NC}"
