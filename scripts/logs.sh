#!/usr/bin/env bash
set -euo pipefail

BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}📋 Streaming live RouterCheck logs (Press Ctrl+C to exit)...${NC}"
log stream --predicate 'process == "RouterCheck" || senderImagePath CONTAINS[c] "RouterCheck"' --level debug --style compact
