#!/usr/bin/env bash

# Ensure the script is run as root (needed for systemctl and disk checks ) 
if [ "$EUID" -ne 0 ]; then 
	echo "Please run as root (or use sudo)" 
	exit 1
fi 

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Source Configuration and Libraries 
source "${SCRIPT_DIR}/conf/settings.env"
source "${SCRIPT_DIR}/lib/logger.sh"
source "${SCRIPT_DIR}/lib/system_checks.sh"
source "${SCRIPT_DIR}/lib/k3s_diagnostics.sh"

echo -e "${GREEN}Staring Node Health Check...${NC}"

# Execute checks 
check_disk_space 
check_system_services 
diagnose_k3s

print_header "Health Check Complete"

