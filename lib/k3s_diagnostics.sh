#!/usr/bin/env bash

diagnose_k3s() {
	print_header "K3s Cluster Diagnostics"


	# Check if kubectl is available first
	if ! command -v kubectl &> /dev/null/; then
		log_warn "kubectl command not found on this node. Skipping cluster API checks."
		return 0
	fi


	# Check systemd service status
	if systemctl is-active --quiet "$K3S_SERVICE_NAME"; then
		log_success "Systemd service '$K3S_SERVICE_NAME" is active."

	else 
		log_error "Systemd service '$K3S_SERVICE_NAME' is NOT active"
		log_info "Fetching recent journal logs to find the error..."
		echo "-------------------------------------------------"
		journalctl -u "$K3S_SERVICE_NAME" --no-pager | tail -n 15
		echo "------------------------------------------------"
		return 1
	fi

	# Check if kubectl is available 
	if ! command -v kubectl &> /dev/null; then 
		log_warn "kubectl command not found on this node. Skipping cluster API checks. " 
		return 0
	fi

	export KUBECONFIG="$KUBECONFIG_PATH"

	# Check Node Readiness
	log_info "Checking Node Status..." 
	local not_ready_nodes=$(kubectl get nodes --no-headers | grep -v "Ready" || true)

	if [-z "$not_ready_nodes" ]; then 
		log_success "All kubernetes nodes are in 'Ready' state."
	else 
		log_error "Found nodes not in 'Ready' state:"
		echo "$not_ready_nodes:
	fi
	
	# Check for crashing core pods (kube-system namespace) 
	log_info "Checking for failing system pods..." 
	local failing_pods=$(kubectl get pods -n kube-system --no-headers | grep -E 'CrashLoopBackOff|Error' || true)

	if [ -z "$failing_pods" ]; then 
		log_success "All kube-system pods are healthy."
	else
		log_error "Found failing pods in kube-system namesapce:"
		echo "$failing_pods"
		log_info "To diagnose, run: kubectl describe pod <pod-name> -n kube-system" 
	fi

}
