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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSIONS_DIR="$SCRIPT_DIR/versions"

mkdir -p "$VERSIONS_DIR"

echo -e "${CYAN}🔍 Checking for server updates...${NC}"
echo ""

UPDATES_FOUND=false

# ==================== PaperMC Check ====================
echo -e "${CYAN}📋 Checking PaperMC...${NC}"

PAPER_VERSION=$(curl -s https://api.papermc.io/v2/projects/paper | jq -r '.versions[-1]')
PAPER_BUILD=$(curl -s "https://api.papermc.io/v2/projects/paper/versions/${PAPER_VERSION}/builds" | jq -r '.builds[-1].build')
PAPER_NEW="${PAPER_VERSION}-${PAPER_BUILD}"

if [ -f "$VERSIONS_DIR/paper.version" ]; then
    PAPER_CURRENT=$(cat "$VERSIONS_DIR/paper.version")
else
    PAPER_CURRENT="none"
fi

echo "  Current: ${PAPER_CURRENT}"
echo "  Latest:  ${PAPER_NEW}"

if [ "$PAPER_CURRENT" != "$PAPER_NEW" ]; then
    echo -e "  ${GREEN}📥 PaperMC update available!${NC}"
    echo "$PAPER_NEW" > "$VERSIONS_DIR/paper.version"
    
    # Update menu.sh with new URL
    PAPER_URL="https://api.papermc.io/v2/projects/paper/versions/${PAPER_VERSION}/builds/${PAPER_BUILD}/downloads/paper-${PAPER_VERSION}-${PAPER_BUILD}.jar"
    sed -i "s|wget -O server.jar \"https://fill-data.papermc.io/.*|wget -O server.jar \"${PAPER_URL}\"|" "$SCRIPT_DIR/menu.sh"
    sed -i "s|wget -O server.jar \"https://api.papermc.io/.*|wget -O server.jar \"${PAPER_URL}\"|" "$SCRIPT_DIR/menu.sh"
    
    UPDATES_FOUND=true
else
    echo -e "  ${GREEN}✓ PaperMC is up to date${NC}"
fi

echo ""

# ==================== Purpur Check ====================
echo -e "${CYAN}📋 Checking Purpur...${NC}"

PURPUR_VERSION=$(curl -s https://api.purpurmc.org/v2/purpur | jq -r '.versions[-1]')
PURPUR_BUILD=$(curl -s "https://api.purpurmc.org/v2/purpur/${PURPUR_VERSION}" | jq -r '.builds.all[-1]')
PURPUR_NEW="${PURPUR_VERSION}-${PURPUR_BUILD}"

if [ -f "$VERSIONS_DIR/purpur.version" ]; then
    PURPUR_CURRENT=$(cat "$VERSIONS_DIR/purpur.version")
else
    PURPUR_CURRENT="none"
fi

echo "  Current: ${PURPUR_CURRENT}"
echo "  Latest:  ${PURPUR_NEW}"

if [ "$PURPUR_CURRENT" != "$PURPUR_NEW" ]; then
    echo -e "  ${GREEN}📥 Purpur update available!${NC}"
    echo "$PURPUR_NEW" > "$VERSIONS_DIR/purpur.version"
    UPDATES_FOUND=true
else
    echo -e "  ${GREEN}✓ Purpur is up to date${NC}"
fi

echo ""

# ==================== PowerNukkitX Check ====================
echo -e "${MAGENTA}📋 Checking PowerNukkitX...${NC}"

PNX_RELEASE=$(curl -s https://api.github.com/repos/PowerNukkitX/PowerNukkitX/releases/latest | jq -r '.tag_name')

if [ -f "$VERSIONS_DIR/powernukkitx.version" ]; then
    PNX_CURRENT=$(cat "$VERSIONS_DIR/powernukkitx.version")
else
    PNX_CURRENT="none"
fi

echo "  Current: ${PNX_CURRENT}"
echo "  Latest:  ${PNX_RELEASE}"

if [ "$PNX_CURRENT" != "$PNX_RELEASE" ]; then
    echo -e "  ${GREEN}📥 PowerNukkitX update available!${NC}"
    echo "$PNX_RELEASE" > "$VERSIONS_DIR/powernukkitx.version"
    
    # Get new download URL
    PNX_URL=$(curl -s https://api.github.com/repos/PowerNukkitX/PowerNukkitX/releases/latest | jq -r '.assets[] | select(.name | contains("powernukkitx")) | .browser_download_url' | head -1)
    
    if [ -z "$PNX_URL" ]; then
        PNX_URL="https://github.com/PowerNukkitX/PowerNukkitX/releases/download/${PNX_RELEASE}/powernukkitx.jar"
    fi
    
    # Update menu.sh
    sed -i "s|wget -O powernukkitx.jar \"https://github.com/PowerNukkitX/.*|wget -O powernukkitx.jar \"${PNX_URL}\"|" "$SCRIPT_DIR/menu.sh"
    
    UPDATES_FOUND=true
else
    echo -e "  ${GREEN}✓ PowerNukkitX is up to date${NC}"
fi

echo ""

# ==================== Summary ====================
if [ "$UPDATES_FOUND" = true ]; then
    echo -e "${GREEN}🎉 Updates found and applied!${NC}"
    echo -e "${YELLOW}📤 Remember to push changes to GitHub:${NC}"
    echo "  git add -A"
    echo "  git commit -m \"Auto-update server versions\""
    echo "  git push"
else
    echo -e "${GREEN}✅ All server software is up to date!${NC}"
fi

echo ""
echo -e "${CYAN}📅 Next check: Run this script daily or setup cron job${NC}"