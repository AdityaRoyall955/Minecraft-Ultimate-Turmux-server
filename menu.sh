#!/data/data/com.termux/files/usr/bin/bash

NC="\e[0m"
GREEN="\e[1;32m"
CYAN="\e[1;36m"
YELLOW="\e[1;33m"
RED="\e[1;31m"

# Source configuration file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/core/server.conf" ]]; then
    source "$SCRIPT_DIR/core/server.conf"
fi

# Set defaults if not configured
SERVER_RAM="${SERVER_RAM:-1500M}"
SERVER_TYPE="${SERVER_TYPE:-Paper}"
MIN_RAM="${MIN_RAM:-1000M}"

SERVER_CMD="java -Xmx${SERVER_RAM} -Xms${MIN_RAM} -jar server.jar --nogui"

# Function to download server jar
download_server() {
    echo -e "${CYAN}📥 Downloading ${SERVER_TYPE} server...${NC}"
    cd "$SCRIPT_DIR" || exit 1
    
    case "$SERVER_TYPE" in
        Paper)
            LATEST_BUILD=$(curl -s https://api.papermc.io/v2/projects/paper/versions/1.20.4/builds | jq -r '.builds[-1].build')
            wget -O server.jar "https://api.papermc.io/v2/projects/paper/versions/1.20.4/builds/${LATEST_BUILD}/downloads/paper-1.20.4-${LATEST_BUILD}.jar"
            ;;
        Purpur)
            wget -O server.jar "https://api.purpurmc.org/v2/purpur/1.20.4/latest/download"
            ;;
        *)
            echo -e "${RED}❌ Unknown server type: ${SERVER_TYPE}${NC}"
            exit 1
            ;;
    esac
    
    if [[ -f "server.jar" ]]; then
        echo -e "${GREEN}✅ Server jar downloaded!${NC}"
    else
        echo -e "${RED}❌ Failed to download server jar!${NC}"
        exit 1
    fi
}

echo -e "${GREEN}🔥 Minecraft Panel Pro Loaded!${NC}"

check_server_jar() {
    if [[ ! -f "$SCRIPT_DIR/server.jar" ]]; then
        echo -e "${YELLOW}⚠️  Server jar not found!${NC}"
        download_server
    fi
}

case "$2" in
    setup)
        bash "$SCRIPT_DIR/scripts/setup_server.sh"
        ;;
    start)
        check_server_jar
        cd "$SCRIPT_DIR" || exit 1
        echo -e "${CYAN}🚀 Starting server with ${SERVER_RAM} RAM...${NC}"
        $SERVER_CMD
        ;;
    restart)
        check_server_jar
        cd "$SCRIPT_DIR" || exit 1
        echo -e "${YELLOW}🔄 Restarting server...${NC}"
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
        bash "$SCRIPT_DIR/plugins/download_plugins.sh"
        ;;
    update)
        check_server_jar
        echo -e "${CYAN}🔄 Updating server jar...${NC}"
        rm -f "$SCRIPT_DIR/server.jar"
        download_server
        ;;
    status)
        if pgrep -f "server.jar" > /dev/null; then
            echo -e "${GREEN}✅ Server is running!${NC}"
        else
            echo -e "${YELLOW}⏹️  Server is not running.${NC}"
        fi
        ;;
    *)
        echo "Usage: mc -s <command>"
        echo ""
        echo "Commands:"
        echo "  setup     - Install dependencies and setup server"
        echo "  start     - Start the Minecraft server"
        echo "  restart   - Restart the Minecraft server"
        echo "  stop      - Request server stop"
        echo "  delete    - Delete world and plugin files (DANGER!)"
        echo "  plugins   - Download default plugins"
        echo "  update    - Update server jar to latest version"
        echo "  status    - Check if server is running"
        ;;
esac
