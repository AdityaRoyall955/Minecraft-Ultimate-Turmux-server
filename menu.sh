#!/data/data/com.termux/files/usr/bin/bash

NC="\e[0m"
GREEN="\e[1;32m"
CYAN="\e[1;36m"
YELLOW="\e[1;33m"
RED="\e[1;31m"
BLUE="\e[1;34m"
MAGENTA="\e[1;35m"

# Source configuration file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/core/server.conf" ]]; then
    source "$SCRIPT_DIR/core/server.conf"
fi

# Set defaults if not configured
SERVER_RAM="${SERVER_RAM:-1500M}"
SERVER_TYPE="${SERVER_TYPE:-Paper}"
MIN_RAM="${MIN_RAM:-1000M}"

# Determine server jar name based on type
if [[ "$SERVER_TYPE" == "PowerNukkitX" ]]; then
    SERVER_JAR="powernukkitx.jar"
else
    SERVER_JAR="server.jar"
fi

SERVER_CMD="java -Xmx${SERVER_RAM} -Xms${MIN_RAM} -jar ${SERVER_JAR} --nogui"

# Function to download server jar
download_server() {
    echo -e "${CYAN}📥 Downloading ${SERVER_TYPE} server...${NC}"
    cd "$SCRIPT_DIR" || exit 1
    
    case "$SERVER_TYPE" in
        Paper)
            echo -e "${YELLOW}⬇️  Downloading PaperMC...${NC}"
            wget -O server.jar "https://fill-data.papermc.io/v1/objects/bd3a58cf96874e5ea6643f5f6fe9b4f5bf9e34b795fa078c2f0ee8b98b2f907e/paper-26.2-112.jar"
            ;;
        Purpur)
            echo -e "${YELLOW}⬇️  Downloading Purpur...${NC}"
            wget -O server.jar "https://api.purpurmc.org/v2/purpur/1.20.4/latest/download"
            ;;
        PowerNukkitX)
            echo -e "${MAGENTA}⬇️  Downloading PowerNukkitX (Bedrock)...${NC}"
            wget -O powernukkitx.jar "https://github.com/PowerNukkitX/PowerNukkitX/releases/download/3.0.2/powernukkitx.jar"
            ;;
        *)
            echo -e "${RED}❌ Unknown server type: ${SERVER_TYPE}${NC}"
            exit 1
            ;;
    esac
    
    if [[ -f "${SERVER_JAR}" ]]; then
        echo -e "${GREEN}✅ ${SERVER_TYPE} server jar downloaded!${NC}"
    else
        echo -e "${RED}❌ Failed to download server jar!${NC}"
        exit 1
    fi
}

# Software selection menu
select_software() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         SELECT MINECRAFT SERVER SOFTWARE       ║${NC}"
    echo -e "${BLUE}╠════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}[1] PaperMC${NC}     - Java Edition (Recommended) ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${CYAN}[2] Purpur${NC}      - Java Edition (Fork)       ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${MAGENTA}[3] PowerNukkitX${NC} - Bedrock Edition         ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    read -p "Enter your choice (1-3): " choice
    
    case "$choice" in
        1)
            SERVER_TYPE="Paper"
            echo -e "${GREEN}✅ Selected: PaperMC (Java)${NC}"
            ;;
        2)
            SERVER_TYPE="Purpur"
            echo -e "${GREEN}✅ Selected: Purpur (Java)${NC}"
            ;;
        3)
            SERVER_TYPE="PowerNukkitX"
            echo -e "${GREEN}✅ Selected: PowerNukkitX (Bedrock)${NC}"
            ;;
        *)
            echo -e "${YELLOW}⚠️  Invalid choice, defaulting to PaperMC${NC}"
            SERVER_TYPE="Paper"
            ;;
    esac
    
    # Save selection to config
    echo "# Minecraft Server Configuration" > "$SCRIPT_DIR/core/server.conf"
    echo "SERVER_RAM=${SERVER_RAM:-1500M}" >> "$SCRIPT_DIR/core/server.conf"
    echo "MIN_RAM=${MIN_RAM:-1000M}" >> "$SCRIPT_DIR/core/server.conf"
    echo "SERVER_TYPE=${SERVER_TYPE}" >> "$SCRIPT_DIR/core/server.conf"
    echo "JAVA_VERSION=${JAVA_VERSION:-21}" >> "$SCRIPT_DIR/core/server.conf"
    echo "MC_VERSION=${MC_VERSION:-1.20.4}" >> "$SCRIPT_DIR/core/server.conf"
    
    echo -e "${CYAN}💾 Configuration saved!${NC}"
}

echo -e "${GREEN}🔥 Minecraft Panel Pro Loaded!${NC}"

check_server_jar() {
    if [[ ! -f "$SCRIPT_DIR/${SERVER_JAR}" ]]; then
        echo -e "${YELLOW}⚠️  Server jar not found!${NC}"
        download_server
    fi
}

case "$2" in
    setup)
        select_software
        bash "$SCRIPT_DIR/scripts/setup_server.sh"
        ;;
    start)
        check_server_jar
        cd "$SCRIPT_DIR" || exit 1
        echo -e "${CYAN}🚀 Starting ${SERVER_TYPE} server with ${SERVER_RAM} RAM...${NC}"
        $SERVER_CMD
        ;;
    restart)
        check_server_jar
        cd "$SCRIPT_DIR" || exit 1
        echo -e "${YELLOW}🔄 Restarting ${SERVER_TYPE} server...${NC}"
        $SERVER_CMD
        ;;
    stop)
        echo -e "${RED}🛑 Sending stop command to server...${NC}"
        touch "$SCRIPT_DIR/.stop_requested"
        ;;
    delete)
        echo -e "${RED}❌ Deleting server files...${NC}"
        read -p "Are you sure? This cannot be undone! (yes/no): " confirm
        if [[ "$confirm" == "yes" ]]; then
            rm -rf "$SCRIPT_DIR/world" "$SCRIPT_DIR/world_nether" "$SCRIPT_DIR/world_the_end" "$SCRIPT_DIR/plugins"
            echo -e "${GREEN}✅ Server files deleted!${NC}"
        else
            echo -e "${YELLOW}⚠️  Cancelled.${NC}"
        fi
        ;;
    plugins)
        if [[ "$SERVER_TYPE" == "PowerNukkitX" ]]; then
            echo -e "${YELLOW}⚠️  PowerNukkitX uses different plugin format (.nukkit)${NC}"
            echo -e "${CYAN}ℹ️  Place .jar plugins in the plugins folder manually${NC}"
        else
            bash "$SCRIPT_DIR/plugins/download_plugins.sh"
        fi
        ;;
    update)
        check_server_jar
        echo -e "${CYAN}🔄 Updating ${SERVER_TYPE} server jar...${NC}"
        rm -f "$SCRIPT_DIR/${SERVER_JAR}"
        download_server
        ;;
    status)
        if pgrep -f "${SERVER_JAR}" > /dev/null; then
            echo -e "${GREEN}✅ ${SERVER_TYPE} server is running!${NC}"
        else
            echo -e "${YELLOW}⏹️  ${SERVER_TYPE} server is not running.${NC}"
        fi
        ;;
    software)
        select_software
        ;;
    *)
        echo "Usage: mc -s <command>"
        echo ""
        echo "Commands:"
        echo "  setup      - Select software & install dependencies"
        echo "  start      - Start the Minecraft server"
        echo "  restart    - Restart the Minecraft server"
        echo "  stop       - Request server stop"
        echo "  delete     - Delete world and plugin files (DANGER!)"
        echo "  plugins    - Download plugins (Java only)"
        echo "  update     - Update server jar to latest version"
        echo "  status     - Check if server is running"
        echo "  software   - Change server software"
        ;;
esac
