#!/usr/bin/env bash

diagnose_k3s() {
	print_header "K3s Cluster Diagnostics" 
	
	#1. Check systemd service status
	if systemctl is-active --quiet "$K3S_SERVICE_NAME"; then 
		log_success "Systemd service '$K3S_SERVICE_NAME' is active."
	else
		log_error "Systemd service '$K3S_SERVICE_NAME' is NOT active."
		log_info "Fetching recent journal logs to find the error." 
		echo "--------------------------------------------------"
		journalctl -u "$K3S_SERVICE_NAME" --no-pager | tail -n 15
		echo "-------------------------------------------------" 
		return 1 # Exit function early, no need to check kubectl
	fi 

	#2. Check if kubectl is available 
	if ! command -v  kubectl &> /dev/null; then
		log_warn "kubectl command not found on this node. Skipping cluster API checks."
		return 0
	fi

	export KUBECONFIG="$KUBECONFIG_PATH"

	# 3. Check Node Readiness
	log_info "Checking Node Status"
	local not_ready_nodes=$(kubectl get nodes --no-headers | grep -v "Ready" || true)

	if [ -z "$not_ready_nodes" ]; then 
		log_success "All Kubernetes nodes are in 'Ready' state."
	else
		log_error "Found nodes not in 'Ready' state:"
		echo "$not_ready_nodes"
	fi

	# 4. Check for crashing core pods (kube-system namespace) 
	log_info "Checking for failing system pods..." 
	local failing_pods=$(kubectl get pods -n kube-system --no-headers | grep -E 'CrashLoopBackOff|Error' || true)

	if [ -z "$failing_pods" ]; then 
		log_success "All kube-system pods are healthy."
	else 
		log_error "Found failing pods in kube-system namespace:"
		echo "$failing_pods"
	fi

	# 5. Check User App Namespaces 
	print_header "Checking User Applications"

	# Dynamically get namespaces excluding kube-* and default
	local dynamic_namespaces=$(kubectl get namespaces --no-headers | awk '{print $1}' | grep -vE "^kube-|^default$" || true)

	# Check if the list is empty
	if [ -z "$dynamic_namespaces" ]; then 
		log_info "No custom user namespaces found to check."
	else
		for ns in $dynamic_namespaces; do
			log_info "Checking apps in namespace: $ns"

			#grep for bad states 
			local failing_apps=$(kubectl get pods -n "$ns" --no-headers | grep -E 'CrashLoopBackOff|Error|ImagePullBackOff|Pending' || true)

			if [ -z "$failing_apps" ]; then
				log_success "All apps in '$ns' are healthy."
			else
				log_error "Failing apps found in '$ns':"
				echo "$failing_apps"
			fi
		done
	fi

}
