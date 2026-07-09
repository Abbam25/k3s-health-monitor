#!/usr/bin/env bash

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

# Colors
if [ -t 1 ]; then
  GREEN="\033[0;32m"
  YELLOW="\033[0;33m"
  RED="\033[0;31m"
  BLUE="\033[0;34m"
  BOLD="\033[1m"
  RESET="\033[0m"
else
  GREEN=""
  YELLOW=""
  RED=""
  BLUE=""
  BOLD=""
  RESET=""
fi

banner() {
  echo -e "${BLUE}${BOLD}"
  cat <<'EOF'
  _   _  ___  __  __ _____ _        _    ____  
 | | | |/ _ \|  \/  | ____| |      / \  | __ ) 
 | |_| | | | | |\/| |  _| | |     / _ \ |  _ \ 
 |  _  | |_| | |  | | |___| |___ / ___ \| |_) |
 |_| |_|\___/|_|  |_|_____|_____/_/   \_\____/ 
EOF
  echo -e "${RESET}"
}

pass() {
  echo -e "${GREEN}[PASS]${RESET} $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

warn() {
  echo -e "${YELLOW}[WARN]${RESET} $1"
  WARN_COUNT=$((WARN_COUNT + 1))
}

fail() {
  echo -e "${RED}[FAIL]${RESET} $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

section() {
  echo
  echo -e "${BOLD}$1${RESET}"
  echo "$(printf '=%.0s' $(seq 1 ${#1}))"
}

summary() {
  echo
  echo -e "${BOLD}Summary:${RESET}"
  echo -e "${GREEN}PASS:${RESET} $PASS_COUNT"
  echo -e "${YELLOW}WARN:${RESET} $WARN_COUNT"
  echo -e "${RED}FAIL:${RESET} $FAIL_COUNT"

  if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 2
  elif [ "$WARN_COUNT" -gt 0 ]; then
    exit 1
  else
    exit 0
  fi
}
