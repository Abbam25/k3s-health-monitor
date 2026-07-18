#!usr/bin/env bash

check_system_services() {
	print_header "Checking Base System Services"

	for service in "${SYSTEM_SERVICES[@]}"; do
		if systemctl is-active --quiet "$service"; then
			log_success "Service '$service' is running."
		else 
			log_error "Service '$service' is down or missing!"
		fi 
	done

}

check_disk_space(){
	print_header "Checking Disk Space"

	# Get usage of root partition, remove % sign
	local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
	
	if [ "$disk_usage" -ge "$DISK_WARNING_THRESHOLD" ]; then
		log_warn "Root disk is at ${disk_usage}% (Threshold: ${DISK_WARNING_THRESHOLD}%)"
	else 
		log_success "Root disk usage is healthy at ${disk_usage}%"
	fi

}
