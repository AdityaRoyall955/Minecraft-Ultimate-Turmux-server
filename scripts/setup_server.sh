#!/data/data/com.termux/files/usr/bin/bash

NC="\e[0m"
GREEN="\e[1;32m"
CYAN="\e[1;36m"
YELLOW="\e[1;33m"
RED="\e[1;31m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "$SCRIPT_DIR/core/server.conf" ]]; then
    source "$SCRIPT_DIR/core/server.conf"
    echo -e "${CYAN}📋 Loaded configuration${NC}"
else
    echo -e "${YELLOW}⚠️  No config found, using defaults${NC}"
    JAVA_VERSION=21
fi

echo -e "${CYAN}📦 Updating packages...${NC}"
pkg update -y

echo -e "${CYAN}☕ Installing OpenJDK ${JAVA_VERSION}...${NC}"
pkg install -y "openjdk-${JAVA_VERSION}" wget curl jq git nano

echo -e "${GREEN}✅ Java installed!${NC}"
java -version

echo -e "${CYAN}📁 Creating server directories...${NC}"
mkdir -p "$SCRIPT_DIR/plugins"
mkdir -p "$SCRIPT_DIR/world"
mkdir -p "$SCRIPT_DIR/backups"

echo -e "${CYAN}📝 Accepting EULA...${NC}"
echo "eula=true" > "$SCRIPT_DIR/eula.txt"
echo -e "${GREEN}✅ EULA accepted!${NC}"

if [[ ! -f "$SCRIPT_DIR/server.properties" ]]; then
echo -e "${CYAN}⚙️  Creating default server.properties...${NC}"
cat > "$SCRIPT_DIR/server.properties" << 'EOF'
#Minecraft server properties
gamemode=survival
level-name=world
motd=§aMinecraft Server §7- §fRunning on Termux
pvp=true
difficulty=easy
max-players=20
online-mode=true
server-port=25565
allow-nether=true
spawn-npcs=true
spawn-animals=true
spawn-monsters=true
view-distance=10
simulation-distance=10
EOF
echo -e "${GREEN}✅ Default server.properties created!${NC}"
fi

echo ""
echo -e "${GREEN}✅ Dependencies installed!${NC}"
echo -e "${CYAN}🚀 Next steps:${NC}"
echo "  1. mc -s plugins  - Download default plugins"
echo "  2. mc -s start    - Start your server!"
