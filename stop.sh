#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Stopping AutoMuteUs Services ===${NC}"

BOT_PIDS=$(pgrep -f "./automuteus" 2>/dev/null || true)
GALACTUS_PIDS=$(pgrep -f "./galactus" 2>/dev/null || true)

if [ -n "$BOT_PIDS" ]; then
    echo -e "${YELLOW}Stopping bot (PID: $BOT_PIDS)...${NC}"
    kill -TERM $BOT_PIDS 2>/dev/null || true
    sleep 1
    echo -e "${GREEN}✓ Bot stopped${NC}"
else
    echo -e "${YELLOW}No running bot found${NC}"
fi

if [ -n "$GALACTUS_PIDS" ]; then
    echo -e "${YELLOW}Stopping Galactus (PID: $GALACTUS_PIDS)...${NC}"
    kill -TERM $GALACTUS_PIDS 2>/dev/null || true
    sleep 1
    echo -e "${GREEN}✓ Galactus stopped${NC}"
else
    echo -e "${YELLOW}No running Galactus found${NC}"
fi

echo ""
read -p "Stop Redis and PostgreSQL services too? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Stopping services...${NC}"
    sudo systemctl stop redis-server 2>/dev/null || sudo service redis-server stop 2>/dev/null || true
    sudo systemctl stop postgresql 2>/dev/null || sudo service postgresql stop 2>/dev/null || true
    echo -e "${GREEN}✓ Services stopped${NC}"
fi

echo -e "${GREEN}Done.${NC}"
