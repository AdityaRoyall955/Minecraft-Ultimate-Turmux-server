#!/data/data/com.termux/files/usr/bin/bash

NC="\e[0m"
GREEN="\e[1;32m"
CYAN="\e[1;36m"
YELLOW="\e[1;33m"
RED="\e[1;31m"
BLUE="\e[1;34m"
MAGENTA="\e[1;35m"
WHITE="\e[1;37m"

# GitHub Repo URL (for checking updates)
REPO_OWNER="AdityaRoyall955"
REPO_NAME="Minecraft-Ultimate-Turmux-server"
REPO_RAW_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main"

# Source configuration file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/core/server.conf" ]]; then
    source "$SCRIPT_DIR/core/server.conf"
fi

# Set defaults if not configured
SERVER_RAM="${SERVER_RAM:-1500M}"
SERVER_TYPE="${SERVER_TYPE:-Paper}"
MIN_RAM="${MIN_RAM:-1000M}"

# Local versions directory
LOCAL_VERSIONS_DIR="$SCRIPT_DIR/versions"
mkdir -p "$LOCAL_VERSIONS_DIR"

# Determine server jar name and version file based on type
case "$SERVER_TYPE" in
    Paper)
        SERVER_JAR="server.jar"
        VERSION_FILE="paper.version"
        ;;
    Purpur)
        SERVER_JAR="server.jar"
        VERSION_FILE="purpur.version"
        ;;
    PowerNukkitX)
        SERVER_JAR="powernukkitx.jar"
        VERSION_FILE="powernukkitx.version"
        ;;
    *)
        SERVER_JAR="server.jar"
        VERSION_FILE="paper.version"
        ;;
esac

SERVER_CMD="java -Xmx${SERVER_RAM} -Xms${MIN_RAM} -jar ${SERVER_JAR} --nogui"

# Function to get download URL from repo
download_server() {
    echo -e "${CYAN}📥 Downloading ${SERVER_TYPE} server...${NC}"
    cd "$SCRIPT_DIR" || exit 1
    
    case "$SERVER_TYPE" in
        Paper)
            echo -e "${YELLOW}⬇️  Downloading PaperMC 1.26...${NC}"
            # Minecraft 2026 - Paper 1.26.x
            wget -O server.jar "https://api.papermc.io/v2/projects/paper/versions/1.26.2/builds/112/downloads/paper-1.26.2-112.jar"
            ;;
        Purpur)
            echo -e "${YELLOW}⬇️  Downloading Purpur 1.26...${NC}"
            # Minecraft 2026 - Purpur 1.26.x
            wget -O server.jar "https://api.purpurmc.org/v2/purpur/1.26.2/2325/download"
            ;;
        PowerNukkitX)
            echo -e "${MAGENTA}⬇️  Downloading PowerNukkitX (Bedrock)...${NC}"
            # Get latest URL from repo
            PNX_REPO_VERSION=$(curl -s "${REPO_RAW_URL}/versions/powernukkitx.version")
            if [[ -n "$PNX_REPO_VERSION" ]]; then
                echo -e "${CYAN}📋 Repo version: ${PNX_REPO_VERSION}${NC}"
            fi
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

# Function to check for updates from repo
check_repo_update() {
    echo -e "${CYAN}🔍 Checking ${REPO_OWNER}/${REPO_NAME} for updates...${NC}"
    echo ""
    
    # Get latest version from GitHub repo
    REPO_VERSION=$(curl -s "${REPO_RAW_URL}/versions/${VERSION_FILE}" 2>/dev/null)
    
    if [[ -z "$REPO_VERSION" ]]; then
        echo -e "${YELLOW}⚠️  Could not fetch version from repo${NC}"
        echo -e "${YELLOW}   Using local download...${NC}"
        return 1
    fi
    
    # Get local version
    if [[ -f "$LOCAL_VERSIONS_DIR/${VERSION_FILE}" ]]; then
        LOCAL_VERSION=$(cat "$LOCAL_VERSIONS_DIR/${VERSION_FILE}")
    else
        LOCAL_VERSION="none"
    fi
    
    echo -e "${WHITE}📱 Local version:  ${LOCAL_VERSION}${NC}"
    echo -e "${GREEN}📦 Repo version:   ${REPO_VERSION}${NC}"
    echo ""
    
    if [[ "$LOCAL_VERSION" != "$REPO_VERSION" ]]; then
        echo -e "${GREEN}🎉 New version available!${NC}"
        return 0
    else
        echo -e "${GREEN}✅ You have the latest version!${NC}"
        return 1
    fi
}

# Function to update server from repo
update_from_repo() {
    echo -e "${CYAN}🔄 Checking for ${SERVER_TYPE} updates...${NC}"
    echo ""
    
    # Get latest version from GitHub repo
    REPO_VERSION=$(curl -s "${REPO_RAW_URL}/versions/${VERSION_FILE}" 2>/dev/null)
    
    if [[ -z "$REPO_VERSION" ]]; then
        echo -e "${YELLOW}⚠️  Could not connect to repo${NC}"
        echo -e "${CYAN}🔄 Updating with built-in URL...${NC}"
        rm -f "$SCRIPT_DIR/${SERVER_JAR}"
        download_server
        return
    fi
    
    # Get local version
    if [[ -f "$LOCAL_VERSIONS_DIR/${VERSION_FILE}" ]]; then
        LOCAL_VERSION=$(cat "$LOCAL_VERSIONS_DIR/${VERSION_FILE}")
    else
        LOCAL_VERSION="none"
    fi
    
    echo -e "${WHITE}📱 Current version:  ${LOCAL_VERSION}${NC}"
    echo -e "${GREEN}📦 Latest version:   ${REPO_VERSION}${NC}"
    echo ""
    
    if [[ "$LOCAL_VERSION" != "$REPO_VERSION" ]]; then
        echo -e "${GREEN}📥 Downloading update...${NC}"
        
        # Backup old jar
        if [[ -f "$SCRIPT_DIR/${SERVER_JAR}" ]]; then
            echo -e "${YELLOW}💾 Backing up current jar...${NC}"
            mv "$SCRIPT_DIR/${SERVER_JAR}" "$SCRIPT_DIR/${SERVER_JAR}.backup"
        fi
        
        # Download new version
        rm -f "$SCRIPT_DIR/${SERVER_JAR}"
        download_server
        
        # Update local version file
        echo "$REPO_VERSION" > "$LOCAL_VERSIONS_DIR/${VERSION_FILE}"
        
        echo ""
        echo -e "${GREEN}✅ ${SERVER_TYPE} updated to ${REPO_VERSION}!${NC}"
        echo -e "${CYAN}🚀 Run 'mc -s start' to use the new version${NC}"
    else
        echo -e "${GREEN}✅ Already up to date!${NC}"
        
        # Check if jar exists, if not download it
        if [[ ! -f "$SCRIPT_DIR/${SERVER_JAR}" ]]; then
            echo -e "${YELLOW}⚠️  Server jar missing, downloading...${NC}"
            download_server
            echo "$REPO_VERSION" > "$LOCAL_VERSIONS_DIR/${VERSION_FILE}"
        fi
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
            VERSION_FILE="paper.version"
            SERVER_JAR="server.jar"
            echo -e "${GREEN}✅ Selected: PaperMC (Java)${NC}"
            ;;
        2)
            SERVER_TYPE="Purpur"
            VERSION_FILE="purpur.version"
            SERVER_JAR="server.jar"
            echo -e "${GREEN}✅ Selected: Purpur (Java)${NC}"
            ;;
        3)
            SERVER_TYPE="PowerNukkitX"
            VERSION_FILE="powernukkitx.version"
            SERVER_JAR="powernukkitx.jar"
            echo -e "${GREEN}✅ Selected: PowerNukkitX (Bedrock)${NC}"
            ;;
        *)
            echo -e "${YELLOW}⚠️  Invalid choice, defaulting to PaperMC${NC}"
            SERVER_TYPE="Paper"
            VERSION_FILE="paper.version"
            SERVER_JAR="server.jar"
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
    # First check if we need to update from repo
    if [[ -f "$LOCAL_VERSIONS_DIR/${VERSION_FILE}" ]]; then
        LOCAL_VER=$(cat "$LOCAL_VERSIONS_DIR/${VERSION_FILE}")
        REPO_VER=$(curl -s "${REPO_RAW_URL}/versions/${VERSION_FILE}" 2>/dev/null)
        
        if [[ -n "$REPO_VER" && "$LOCAL_VER" != "$REPO_VER" ]]; then
            echo -e "${YELLOW}⚠️  New version available in repo: ${REPO_VER}${NC}"
            echo -e "${CYAN}   Run 'mc -s update' to get the latest version${NC}"
            echo ""
        fi
    fi
    
    if [[ ! -f "$SCRIPT_DIR/${SERVER_JAR}" ]]; then
        echo -e "${YELLOW}⚠️  Server jar not found!${NC}"
        download_server
        # Save version after download
        REPO_VER=$(curl -s "${REPO_RAW_URL}/versions/${VERSION_FILE}" 2>/dev/null)
        if [[ -n "$REPO_VER" ]]; then
            echo "$REPO_VER" > "$LOCAL_VERSIONS_DIR/${VERSION_FILE}"
        fi
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
        
        # Show current version
        if [[ -f "$LOCAL_VERSIONS_DIR/${VERSION_FILE}" ]]; then
            CURRENT_VER=$(cat "$LOCAL_VERSIONS_DIR/${VERSION_FILE}")
            echo -e "${GREEN}📦 Version: ${CURRENT_VER}${NC}"
        fi
        
        $SERVER_CMD
        ;;
    restart)
        check_server_jar
        cd "$SCRIPT_DIR" || exit 1
        echo -e "${YELLOW}🔄 Restarting ${SERVER_TYPE} server...${NC}"
        
        # Show current version
        if [[ -f "$LOCAL_VERSIONS_DIR/${VERSION_FILE}" ]]; then
            CURRENT_VER=$(cat "$LOCAL_VERSIONS_DIR/${VERSION_FILE}")
            echo -e "${GREEN}📦 Version: ${CURRENT_VER}${NC}"
        fi
        
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
        update_from_repo
        ;;
    check)
        check_repo_update
        ;;
    status)
        if pgrep -f "${SERVER_JAR}" > /dev/null; then
            echo -e "${GREEN}✅ ${SERVER_TYPE} server is running!${NC}"
            # Show version
            if [[ -f "$LOCAL_VERSIONS_DIR/${VERSION_FILE}" ]]; then
                CURRENT_VER=$(cat "$LOCAL_VERSIONS_DIR/${VERSION_FILE}")
                echo -e "${CYAN}📦 Version: ${CURRENT_VER}${NC}"
            fi
        else
            echo -e "${YELLOW}⏹️  ${SERVER_TYPE} server is not running.${NC}"
            # Show version
            if [[ -f "$LOCAL_VERSIONS_DIR/${VERSION_FILE}" ]]; then
                CURRENT_VER=$(cat "$LOCAL_VERSIONS_DIR/${VERSION_FILE}")
                echo -e "${CYAN}📦 Installed version: ${CURRENT_VER}${NC}"
            fi
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
        echo "  update     - Check repo & update to latest version"
        echo "  check      - Check if new version available"
        echo "  status     - Check if server is running"
        echo "  software   - Change server software"
        ;;
esac
