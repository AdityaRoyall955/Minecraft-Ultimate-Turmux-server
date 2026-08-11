#!/data/data/com.termux/files/usr/bin/bash

NC="\e[0m"
GREEN="\e[1;32m"
CYAN="\e[1;36m"
YELLOW="\e[1;33m"
RED="\e[1;31m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGINS_DIR="$SCRIPT_DIR/plugins"

echo -e "${CYAN}📁 Ensuring plugins directory exists...${NC}"
mkdir -p "$PLUGINS_DIR"

echo -e "${CYAN}⬇️  Downloading Geyser (Bedrock crossplay)...${NC}"
wget -q --show-progress -O "$PLUGINS_DIR/Geyser-Spigot.jar" \
    "https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot"

if [[ -f "$PLUGINS_DIR/Geyser-Spigot.jar" ]]; then
    echo -e "${GREEN}✅ Geyser installed!${NC}"
else
    echo -e "${RED}❌ Failed to download Geyser${NC}"
fi

echo -e "${CYAN}⬇️  Downloading Floodgate (auth bridge)...${NC}"
wget -q --show-progress -O "$PLUGINS_DIR/floodgate-spigot.jar" \
    "https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot"

if [[ -f "$PLUGINS_DIR/floodgate-spigot.jar" ]]; then
    echo -e "${GREEN}✅ Floodgate installed!${NC}"
else
    echo -e "${RED}❌ Failed to download Floodgate${NC}"
fi

echo ""
echo -e "${GREEN}✅ Plugins installed to: $PLUGINS_DIR${NC}"
echo -e "${YELLOW}💡 Tip: Start the server to generate plugin configs${NC}"
