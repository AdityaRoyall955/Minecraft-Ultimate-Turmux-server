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
    Folia)
        SERVER_JAR="server.jar"
        VERSION_FILE="folia.version"
        ;;
    Vanilla)
        SERVER_JAR="server.jar"
        VERSION_FILE="vanilla.version"
        ;;
    Fabric)
        SERVER_JAR="server.jar"
        VERSION_FILE="fabric.version"
        ;;
    Spigot)
        SERVER_JAR="server.jar"
        VERSION_FILE="spigot.version"
        ;;
    Custom)
        SERVER_JAR="server.jar"
        VERSION_FILE="custom.version"
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
SERVER_PID_FILE="$SCRIPT_DIR/.server.pid"
SERVER_LOG_FILE="$SCRIPT_DIR/server.log"
MANAGER_PID_FILE="$SCRIPT_DIR/.manager.pid"
MANAGER_LOG_FILE="$SCRIPT_DIR/manager.log"

server_running() {
    [[ -f "$SERVER_PID_FILE" ]] && kill -0 "$(cat "$SERVER_PID_FILE")" 2>/dev/null
}

manager_running() {
    [[ -f "$MANAGER_PID_FILE" ]] && kill -0 "$(cat "$MANAGER_PID_FILE")" 2>/dev/null
}

start_manager() {
    if ! manager_running; then
        rm -f "$MANAGER_PID_FILE"
        SERVER_TYPE="$SERVER_TYPE" nohup python3 "$SCRIPT_DIR/web/manager.py" > "$MANAGER_LOG_FILE" 2>&1 &
        echo $! > "$MANAGER_PID_FILE"
    fi

    MANAGER_URL="http://127.0.0.1:8765"
    if command -v termux-open-url >/dev/null 2>&1; then
        termux-open-url "$MANAGER_URL" >/dev/null 2>&1 &
    elif [[ -n "${BROWSER:-}" ]] && command -v "$BROWSER" >/dev/null 2>&1; then
        "$BROWSER" "$MANAGER_URL" >/dev/null 2>&1 &
    fi
    echo -e "${CYAN}Manager: ${MANAGER_URL}${NC}"
}

start_server() {
    if server_running; then
        echo -e "${YELLOW}Server is already running.${NC}"
        return 0
    fi

    rm -f "$SERVER_PID_FILE"
    nohup java "-Xmx${SERVER_RAM}" "-Xms${MIN_RAM}" -jar "$SERVER_JAR" --nogui \
        > "$SERVER_LOG_FILE" 2>&1 < /dev/null &
    echo $! > "$SERVER_PID_FILE"
    echo -e "${GREEN}${SERVER_TYPE} started in background.${NC}"
    echo -e "${CYAN}Log: ${SERVER_LOG_FILE}${NC}"
}

stop_server() {
    if server_running; then
        kill "$(cat "$SERVER_PID_FILE")" 2>/dev/null || true
        rm -f "$SERVER_PID_FILE"
        echo -e "${GREEN}${SERVER_TYPE} stopped.${NC}"
    else
        rm -f "$SERVER_PID_FILE"
        echo -e "${YELLOW}Server is not running.${NC}"
    fi
}

# Function to auto-detect latest Paper version
get_latest_paper() {
    PAPER_VERSION=$(curl -fsSL https://api.papermc.io/v2/projects/paper | jq -r '.versions[-1]')
    PAPER_BUILD=$(curl -fsSL "https://api.papermc.io/v2/projects/paper/versions/${PAPER_VERSION}/builds" | jq -r '.builds[-1].build')
    echo -e "${GREEN}📦 Latest Paper: ${PAPER_VERSION}-${PAPER_BUILD}${NC}" >&2
    echo "${PAPER_VERSION}-${PAPER_BUILD}" > "$LOCAL_VERSIONS_DIR/paper.version"
    echo "https://api.papermc.io/v2/projects/paper/versions/${PAPER_VERSION}/builds/${PAPER_BUILD}/downloads/paper-${PAPER_VERSION}-${PAPER_BUILD}.jar"
}

# Function to auto-detect latest Purpur version
get_latest_purpur() {
    PURPUR_VERSION=$(curl -fsSL https://api.purpurmc.org/v2/purpur | jq -r '.versions[-1]')
    PURPUR_BUILD=$(curl -fsSL "https://api.purpurmc.org/v2/purpur/${PURPUR_VERSION}" | jq -r '.builds.all[-1]')
    echo -e "${GREEN}📦 Latest Purpur: ${PURPUR_VERSION}-${PURPUR_BUILD}${NC}" >&2
    echo "${PURPUR_VERSION}-${PURPUR_BUILD}" > "$LOCAL_VERSIONS_DIR/purpur.version"
    echo "https://api.purpurmc.org/v2/purpur/${PURPUR_VERSION}/${PURPUR_BUILD}/download"
}

get_latest_folia() {
    FOLIA_VERSION=$(curl -fsSL https://api.papermc.io/v2/projects/folia | jq -r '.versions[-1]')
    FOLIA_BUILD=$(curl -fsSL "https://api.papermc.io/v2/projects/folia/versions/${FOLIA_VERSION}/builds" | jq -r '.builds[-1].build')
    echo -e "${GREEN}📦 Latest Folia: ${FOLIA_VERSION}-${FOLIA_BUILD}${NC}" >&2
    echo "${FOLIA_VERSION}-${FOLIA_BUILD}" > "$LOCAL_VERSIONS_DIR/folia.version"
    echo "https://api.papermc.io/v2/projects/folia/versions/${FOLIA_VERSION}/builds/${FOLIA_BUILD}/downloads/folia-${FOLIA_VERSION}-${FOLIA_BUILD}.jar"
}

get_latest_vanilla() {
    VANILLA_VERSION=$(curl -fsSL https://piston-meta.mojang.com/mc/game/version_manifest_v2.json | jq -r '.latest.release')
    VANILLA_URL=$(curl -fsSL "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json" | jq -r ".versions[] | select(.id == \"${VANILLA_VERSION}\") | .url" | xargs curl -fsSL | jq -r '.downloads.server.url')
    echo -e "${GREEN}📦 Latest Vanilla: ${VANILLA_VERSION}${NC}" >&2
    echo "${VANILLA_VERSION}" > "$LOCAL_VERSIONS_DIR/vanilla.version"
    echo "$VANILLA_URL"
}

get_latest_fabric() {
    FABRIC_VERSION=$(curl -fsSL https://meta.fabricmc.net/v2/versions/game | jq -r '[.[] | select(.stable == true)][0].version')
    FABRIC_LOADER=$(curl -fsSL https://meta.fabricmc.net/v2/versions/loader | jq -r '[.[] | select(.stable == true)][0].version')
    FABRIC_INSTALLER=$(curl -fsSL https://meta.fabricmc.net/v2/versions/installer | jq -r '[.[] | select(.stable == true)][0].version')
    echo -e "${GREEN}📦 Latest Fabric: ${FABRIC_VERSION} / loader ${FABRIC_LOADER}${NC}" >&2
    echo "${FABRIC_VERSION}-${FABRIC_LOADER}" > "$LOCAL_VERSIONS_DIR/fabric.version"
    echo "https://meta.fabricmc.net/v2/versions/loader/${FABRIC_VERSION}/${FABRIC_LOADER}/${FABRIC_INSTALLER}/server/jar"
}

get_latest_spigot() {
    SPIGOT_VERSION=$(curl -fsSL https://piston-meta.mojang.com/mc/game/version_manifest_v2.json | jq -r '.latest.release')
    echo -e "${GREEN}📦 Latest Spigot target: ${SPIGOT_VERSION}${NC}" >&2
    echo "${SPIGOT_VERSION}" > "$LOCAL_VERSIONS_DIR/spigot.version"
    echo "https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar"
}

detect_latest_version() {
    case "$SERVER_TYPE" in
        Paper)
            DETECT_VERSION=$(curl -fsSL https://api.papermc.io/v2/projects/paper | jq -r '.versions[-1]')
            DETECT_BUILD=$(curl -fsSL "https://api.papermc.io/v2/projects/paper/versions/${DETECT_VERSION}/builds" | jq -r '.builds[-1].build')
            REPO_VERSION="${DETECT_VERSION}-${DETECT_BUILD}"
            ;;
        Purpur)
            DETECT_VERSION=$(curl -fsSL https://api.purpurmc.org/v2/purpur | jq -r '.versions[-1]')
            DETECT_BUILD=$(curl -fsSL "https://api.purpurmc.org/v2/purpur/${DETECT_VERSION}" | jq -r '.builds.all[-1]')
            REPO_VERSION="${DETECT_VERSION}-${DETECT_BUILD}"
            ;;
        Folia)
            DETECT_VERSION=$(curl -fsSL https://api.papermc.io/v2/projects/folia | jq -r '.versions[-1]')
            DETECT_BUILD=$(curl -fsSL "https://api.papermc.io/v2/projects/folia/versions/${DETECT_VERSION}/builds" | jq -r '.builds[-1].build')
            REPO_VERSION="${DETECT_VERSION}-${DETECT_BUILD}"
            ;;
        Vanilla|Spigot)
            REPO_VERSION=$(curl -fsSL https://piston-meta.mojang.com/mc/game/version_manifest_v2.json | jq -r '.latest.release')
            ;;
        Fabric)
            DETECT_VERSION=$(curl -fsSL https://meta.fabricmc.net/v2/versions/game | jq -r '[.[] | select(.stable == true)][0].version')
            DETECT_LOADER=$(curl -fsSL https://meta.fabricmc.net/v2/versions/loader | jq -r '[.[] | select(.stable == true)][0].version')
            REPO_VERSION="${DETECT_VERSION}-${DETECT_LOADER}"
            ;;
        PowerNukkitX)
            REPO_VERSION=$(curl -fsSL https://api.github.com/repos/PowerNukkitX/PowerNukkitX/releases/latest | jq -r '.tag_name')
            ;;
        *)
            REPO_VERSION=""
            ;;
    esac
}

# Function to auto-detect latest PowerNukkitX version
get_latest_pnx() {
    echo -e "${CYAN}🔍 Auto-detecting latest PowerNukkitX version...${NC}"
    
    # Get latest release from GitHub
    PNX_VERSION=$(curl -s "https://api.github.com/repos/PowerNukkitX/PowerNukkitX/releases/latest" | grep -o '"tag_name":"[^"]*"' | cut -d'"' -f4)
    if [[ -z "$PNX_VERSION" ]]; then
        PNX_VERSION="3.0.3"
    fi
    
    echo -e "${GREEN}📦 Latest PowerNukkitX: ${PNX_VERSION}${NC}"
    echo "${PNX_VERSION}" > "$LOCAL_VERSIONS_DIR/powernukkitx.version"
    
    DOWNLOAD_URL="https://github.com/PowerNukkitX/PowerNukkitX/releases/download/${PNX_VERSION}/powernukkitx.jar"
    echo "$DOWNLOAD_URL"
}

# Function to get download URL from repo
download_server() {
    echo -e "${CYAN}📥 Downloading ${SERVER_TYPE} server...${NC}"
    cd "$SCRIPT_DIR" || exit 1
    
    case "$SERVER_TYPE" in
        Paper)
            echo -e "${YELLOW}⬇️  Downloading latest PaperMC...${NC}"
            PAPER_URL=$(get_latest_paper)
            wget -O server.jar "$PAPER_URL"
            ;;
        Purpur)
            echo -e "${YELLOW}⬇️  Downloading latest Purpur...${NC}"
            PURPUR_URL=$(get_latest_purpur)
            wget -O server.jar "$PURPUR_URL"
            ;;
        Folia)
            echo -e "${YELLOW}⬇️  Downloading latest Folia...${NC}"
            FOLIA_URL=$(get_latest_folia)
            wget -O server.jar "$FOLIA_URL"
            ;;
        Vanilla)
            echo -e "${YELLOW}⬇️  Downloading latest Vanilla...${NC}"
            VANILLA_URL=$(get_latest_vanilla)
            wget -O server.jar "$VANILLA_URL"
            ;;
        Fabric)
            echo -e "${YELLOW}⬇️  Downloading latest Fabric...${NC}"
            FABRIC_URL=$(get_latest_fabric)
            wget -O server.jar "$FABRIC_URL"
            ;;
        Spigot)
            echo -e "${YELLOW}⬇️  Building latest Spigot with BuildTools...${NC}"
            get_latest_spigot > "$SCRIPT_DIR/.spigot-url"
            SPIGOT_VERSION=$(cat "$LOCAL_VERSIONS_DIR/spigot.version")
            wget -q -O BuildTools.jar "$(cat "$SCRIPT_DIR/.spigot-url")"
            java -jar BuildTools.jar --rev "$SPIGOT_VERSION"
            mv "spigot-${SPIGOT_VERSION}.jar" server.jar
            rm -f BuildTools.jar "$SCRIPT_DIR/.spigot-url"
            ;;
        PowerNukkitX)
            echo -e "${MAGENTA}⬇️  Downloading latest PowerNukkitX (Bedrock)...${NC}"
            PNX_URL=$(get_latest_pnx)
            wget -O powernukkitx.jar "$PNX_URL"
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
        echo -e "${YELLOW}   Using auto-detect...${NC}"
        
        detect_latest_version
    fi
    
    if [[ -z "$REPO_VERSION" ]]; then
        echo -e "${RED}❌ Could not detect version${NC}"
        return 1
    fi
    
    # Get local version
    if [[ -f "$LOCAL_VERSIONS_DIR/${VERSION_FILE}" ]]; then
        LOCAL_VERSION=$(cat "$LOCAL_VERSIONS_DIR/${VERSION_FILE}")
    else
        LOCAL_VERSION="none"
    fi
    
    echo -e "${WHITE}📱 Local version:  ${LOCAL_VERSION}${NC}"
    echo -e "${GREEN}📦 Latest version: ${REPO_VERSION}${NC}"
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
    
    detect_latest_version
    
    if [[ -z "$REPO_VERSION" ]]; then
        echo -e "${YELLOW}⚠️  Could not connect to APIs${NC}"
        echo -e "${CYAN}🔄 Using built-in download...${NC}"
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
    echo -e "${BLUE}║${NC}  ${CYAN}[3] Folia${NC}       - Java Edition (Threads)    ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}[4] Vanilla${NC}     - Official Java Edition    ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}[5] Fabric${NC}      - Java Edition (Mods)       ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${YELLOW}[6] Spigot${NC}      - Java Edition (BuildTools) ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${MAGENTA}[7] PowerNukkitX${NC} - Bedrock Edition         ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    read -p "Enter your choice (1-7): " choice
    
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
            SERVER_TYPE="Folia"
            VERSION_FILE="folia.version"
            SERVER_JAR="server.jar"
            echo -e "${GREEN}✅ Selected: Folia (Java)${NC}"
            ;;
        4)
            SERVER_TYPE="Vanilla"
            VERSION_FILE="vanilla.version"
            SERVER_JAR="server.jar"
            echo -e "${GREEN}✅ Selected: Vanilla (Java)${NC}"
            ;;
        5)
            SERVER_TYPE="Fabric"
            VERSION_FILE="fabric.version"
            SERVER_JAR="server.jar"
            echo -e "${GREEN}✅ Selected: Fabric (Java Mods)${NC}"
            ;;
        6)
            SERVER_TYPE="Spigot"
            VERSION_FILE="spigot.version"
            SERVER_JAR="server.jar"
            echo -e "${GREEN}✅ Selected: Spigot (Java)${NC}"
            ;;
        7)
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
    
    # Auto-detect latest version for config
    case "$SERVER_TYPE" in
        Paper)
            MC_VER=$(curl -s "https://api.papermc.io/v2/projects/paper" | grep -o '"[0-9]\+\.[0-9]\+\.[0-9]\+"' | tr -d '"' | tail -1)
            ;;
        Purpur)
            MC_VER=$(curl -s "https://api.purpurmc.org/v2/purpur" | grep -o '"[0-9]\+\.[0-9]\+\.[0-9]\+"' | tr -d '"' | tail -1)
            ;;
        Folia)
            MC_VER=$(curl -fsSL "https://api.papermc.io/v2/projects/folia" | jq -r '.versions[-1]')
            ;;
        Vanilla|Fabric|Spigot)
            MC_VER=$(curl -fsSL https://piston-meta.mojang.com/mc/game/version_manifest_v2.json | jq -r '.latest.release')
            ;;
        PowerNukkitX)
            MC_VER="latest"
            ;;
    esac
    [[ -z "$MC_VER" ]] && MC_VER="1.26.2"
    
    # Save selection to config
    echo "# Minecraft Server Configuration" > "$SCRIPT_DIR/core/server.conf"
    echo "SERVER_RAM=${SERVER_RAM:-1500M}" >> "$SCRIPT_DIR/core/server.conf"
    echo "MIN_RAM=${MIN_RAM:-1000M}" >> "$SCRIPT_DIR/core/server.conf"
    echo "SERVER_TYPE=${SERVER_TYPE}" >> "$SCRIPT_DIR/core/server.conf"
    echo "JAVA_VERSION=${JAVA_VERSION:-21}" >> "$SCRIPT_DIR/core/server.conf"
    echo "MC_VERSION=${MC_VER}" >> "$SCRIPT_DIR/core/server.conf"
    
    echo -e "${CYAN}💾 Configuration saved!${NC}"
}

echo -e "${GREEN}🔥 Minecraft Panel Pro Loaded!${NC}"

check_server_jar() {
    # First check if we need to update from repo
    if [[ -f "$LOCAL_VERSIONS_DIR/${VERSION_FILE}" ]]; then
        LOCAL_VER=$(cat "$LOCAL_VERSIONS_DIR/${VERSION_FILE}")
        
        detect_latest_version
        REPO_VER="$REPO_VERSION"
        
        if [[ -n "$REPO_VER" && "$LOCAL_VER" != "$REPO_VER" ]]; then
            echo -e "${YELLOW}⚠️  New version available: ${REPO_VER}${NC}"
            echo -e "${CYAN}   Run 'mc -s update' to get the latest version${NC}"
            echo ""
        fi
    fi
    
    if [[ ! -f "$SCRIPT_DIR/${SERVER_JAR}" ]]; then
        echo -e "${YELLOW}⚠️  Server jar not found!${NC}"
        download_server
        # Save version after download
        case "$SERVER_TYPE" in
            Paper|Purpur)
                if [[ -f "$LOCAL_VERSIONS_DIR/${VERSION_FILE}" ]]; then
                    echo "$(cat $LOCAL_VERSIONS_DIR/${VERSION_FILE})" > "$LOCAL_VERSIONS_DIR/${VERSION_FILE}"
                fi
                ;;
        esac
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
        
        start_server
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
        
        stop_server
        start_server
        ;;
    stop)
        echo -e "${RED}🛑 Stopping server...${NC}"
        stop_server
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
        start_manager
        ;;
    mods|manager)
        start_manager
        ;;
    update)
        update_from_repo
        ;;
    check)
        check_repo_update
        ;;
    status)
        if server_running; then
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
        echo "  mods       - Open the local Mods manager"
        echo "  manager    - Open the local Mods and Plugins manager"
        echo "  update     - Check repo & update to latest version"
        echo "  check      - Check if new version available"
        echo "  status     - Check if server is running"
        echo "  software   - Change server software"
        ;;
esac
