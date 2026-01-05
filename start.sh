#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GALACTUS_DIR="/home/cleggas/developer/galactus"
cd "$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

BOT_PID=""
GALACTUS_PID=""

cleanup() {
    echo -e "\n${YELLOW}Shutting down...${NC}"
    
    if [ -n "$BOT_PID" ] && kill -0 "$BOT_PID" 2>/dev/null; then
        echo -e "${YELLOW}Stopping bot (PID: $BOT_PID)...${NC}"
        kill -TERM "$BOT_PID" 2>/dev/null
        wait "$BOT_PID" 2>/dev/null || true
        echo -e "${GREEN}Bot stopped.${NC}"
    fi
    
    if [ -n "$GALACTUS_PID" ] && kill -0 "$GALACTUS_PID" 2>/dev/null; then
        echo -e "${YELLOW}Stopping Galactus (PID: $GALACTUS_PID)...${NC}"
        kill -TERM "$GALACTUS_PID" 2>/dev/null
        wait "$GALACTUS_PID" 2>/dev/null || true
        echo -e "${GREEN}Galactus stopped.${NC}"
    fi
    
    echo -e "${GREEN}Shutdown complete.${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

check_service() {
    local service=$1
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        return 0
    elif service "$service" status >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

start_service() {
    local service=$1
    echo -e "${YELLOW}Starting $service...${NC}"
    if command -v systemctl &>/dev/null; then
        sudo systemctl start "$service" || sudo service "$service" start
    else
        sudo service "$service" start
    fi
}

echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   AutoMuteUs (Modded) Launcher         ║${NC}"
echo -e "${CYAN}║   With ToHE Color-Based Tracking       ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}[1/5] Checking Redis...${NC}"
if check_service "redis-server" || check_service "redis"; then
    echo -e "${GREEN}  ✓ Redis is running${NC}"
else
    echo -e "${RED}  ✗ Redis is not running${NC}"
    read -p "  Start Redis? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        start_service "redis-server" || start_service "redis"
    else
        echo -e "${RED}Cannot continue without Redis. Exiting.${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}[2/5] Checking PostgreSQL...${NC}"
if check_service "postgresql"; then
    echo -e "${GREEN}  ✓ PostgreSQL is running${NC}"
else
    echo -e "${RED}  ✗ PostgreSQL is not running${NC}"
    read -p "  Start PostgreSQL? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        start_service "postgresql"
    else
        echo -e "${RED}Cannot continue without PostgreSQL. Exiting.${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}[3/5] Checking configuration...${NC}"
if [ ! -f ".env" ]; then
    echo -e "${RED}  ✗ .env file not found!${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ .env file found${NC}"

echo -e "${YELLOW}[4/5] Building binaries if needed...${NC}"
if [ ! -f "automuteus" ]; then
    echo -e "${YELLOW}  Building bot...${NC}"
    go build -o automuteus .
fi
echo -e "${GREEN}  ✓ Bot binary ready${NC}"

if [ ! -f "$GALACTUS_DIR/galactus" ]; then
    echo -e "${YELLOW}  Building Galactus...${NC}"
    cd "$GALACTUS_DIR" && go build -o galactus . && cd "$SCRIPT_DIR"
fi
echo -e "${GREEN}  ✓ Galactus binary ready${NC}"

echo -e "${YELLOW}[5/5] Starting services...${NC}"

set -a
source .env
set +a

export REDIS_ADDR="${REDIS_ADDR:-localhost:6379}"
export REDIS_PASS="${REDIS_PASS:-}"
export BROKER_PORT="8123"

echo -e "${CYAN}  Starting Galactus on port 8123...${NC}"
cd "$GALACTUS_DIR"
./galactus 2>&1 | sed 's/^/  [Galactus] /' &
GALACTUS_PID=$!
cd "$SCRIPT_DIR"

sleep 2

if ! kill -0 "$GALACTUS_PID" 2>/dev/null; then
    echo -e "${RED}  ✗ Galactus failed to start${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ Galactus started (PID: $GALACTUS_PID)${NC}"

echo -e "${CYAN}  Starting AutoMuteUs bot...${NC}"
./automuteus 2>&1 | sed 's/^/  [Bot] /' &
BOT_PID=$!

sleep 3

if ! kill -0 "$BOT_PID" 2>/dev/null; then
    echo -e "${RED}  ✗ Bot failed to start${NC}"
    cleanup
    exit 1
fi
echo -e "${GREEN}  ✓ Bot started (PID: $BOT_PID)${NC}"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   All services running!                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Capture URL: ${NC}aucapture://localhost:8123/<code>?insecure"
echo -e "${CYAN}Bot API:     ${NC}http://localhost:5000"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"
echo ""

wait "$BOT_PID" "$GALACTUS_PID"
