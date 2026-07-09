#!/usr/bin/env bash

k() {
  "${KUBECTL_CMD[@]}" "$@"
}

check_kubectl() {
  if kubectl version --client >/dev/null 2>&1 && kubectl cluster-info >/dev/null 2>&1; then
    pass "Kubernetes API reachable"
  else
    fail "Kubernetes API not reachable. Check kubeconfig or k3s service."
  fi
}

check_nodes() {
  local total
  local ready

  total="$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')"
  ready="$(kubectl get nodes --no-headers 2>/dev/null | awk '$2 == "Ready" {count++} END {print count+0}')"

  if [ "$total" -eq 0 ]; then
    fail "No Kubernetes nodes found"
    return
  fi

  if [ "$ready" -eq "$EXPECTED_NODE_COUNT" ]; then
    pass "Nodes Ready: $ready/$EXPECTED_NODE_COUNT"
  elif [ "$ready" -eq "$total" ]; then
    warn "All discovered nodes are Ready, but expected $EXPECTED_NODE_COUNT and found $total"
  else
    fail "Nodes Ready: $ready/$total. Run: kubectl get nodes -o wide"
  fi
}

check_node_pressure() {
  local pressure

  pressure="$(kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{" "}{range .status.conditions[*]}{.type}{"="}{.status}{" "}{end}{"\n"}{end}' 2>/dev/null \
    | grep -E 'MemoryPressure=True|DiskPressure=True|PIDPressure=True|NetworkUnavailable=True' || true)"

  if [ -z "$pressure" ]; then
    pass "No node pressure detected"
  else
    fail "Node pressure detected:"
    echo "$pressure" | sed 's/^/       /'
  fi
}

check_unhealthy_pods() {
  local bad_pods

  bad_pods="$(kubectl get pods -A --no-headers 2>/dev/null \
    | awk '$4 ~ /CrashLoopBackOff|Error|ImagePullBackOff|ErrImagePull|CreateContainerConfigError|CreateContainerError|Pending|Unknown|Failed/ {print}')"

  if [ -z "$bad_pods" ]; then
    pass "No unhealthy pods detected"
  else
    fail "Unhealthy pods found:"
    echo "$bad_pods" | sed 's/^/       /'
  fi
}

check_pod_restarts() {
  local restarted

  restarted="$(kubectl get pods -A --no-headers 2>/dev/null \
    | awk '$5+0 > 3 {print}')"

  if [ -z "$restarted" ]; then
    pass "No pods with high restart count"
  else
    warn "Pods with more than 3 restarts:"
    echo "$restarted" | sed 's/^/       /'
  fi
}

check_pvcs() {
  local bad_pvcs

  bad_pvcs="$(kubectl get pvc -A --no-headers 2>/dev/null \
    | awk '$3 != "Bound" {print}')"

  if [ -z "$bad_pvcs" ]; then
    pass "All PVCs are Bound"
  else
    fail "PVCs not Bound:"
    echo "$bad_pvcs" | sed 's/^/       /'
  fi
}

check_deployments() {
  local bad_deployments

  bad_deployments="$(kubectl get deployments -A --no-headers 2>/dev/null \
    | awk '
      {
        split($3, ready, "/")
        if (ready[1] != ready[2]) {
          print
        }
      }
    ')"

  if [ -z "$bad_deployments" ]; then
    pass "All deployments are Ready"
  else
    fail "Deployments not fully Ready:"
    echo "$bad_deployments" | sed 's/^/       /'
  fi
}
