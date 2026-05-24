#!/data/data/com.termux/files/usr/bin/bash

NC="\e[0m"
GREEN="\e[1;32m"
CYAN="\e[1;36m"
YELLOW="\e[1;33m"
RED="\e[1;31m"

SERVER_CMD="java -Xmx1500M -Xms1000M -jar server.jar --nogui"

echo -e "${GREEN}🔥 Minecraft Panel Pro Loaded!${NC}"

case "$2" in
    setup)
        bash scripts/setup_server.sh
        ;;
    start)
        echo -e "${CYAN}🚀 Starting server...${NC}"
        $SERVER_CMD
        ;;
    restart)
        echo -e "${YELLOW}🔄 Restarting server...${NC}"
        $SERVER_CMD
        ;;
    delete)
        echo -e "${RED}❌ Deleting server files...${NC}"
        rm -rf world world_nether world_the_end plugins
        ;;
    *)
        echo "Usage:"
        echo "mc -s setup"
        echo "mc -s start"
        echo "mc -s restart"
        echo "mc -s delete"
        ;;
esac
