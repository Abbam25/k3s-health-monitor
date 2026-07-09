#!/usr/bin/env bash
set -u
set -o pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$BASE_DIR/config.sh"
source "$BASE_DIR/lib/output.sh"
source "$BASE_DIR/lib/kubernetes.sh"
source "$BASE_DIR/lib/flux.sh"
source "$BASE_DIR/lib/ingress.sh"
source "$BASE_DIR/lib/storage.sh"
source "$BASE_DIR/lib/apps.sh"

echo "K3S HEALTH CHECK REPORT"
echo "Cluster: $CLUSTER_NAME"
echo "Time: $(date)"
echo

section "Cluster"
check_kubectl
check_nodes
check_node_pressure
check_unhealthy_pods
check_pod_restarts
check_pvcs
check_deployments

# section "Flux"
# check_flux_kustomizations
# check_flux_helmreleases

# section "Ingress"
# check_ingress_service
# check_external_urls

# section "Storage"
# check_qbittorrent_downloads
# check_jellyfin_media

# section "Applications"
# check_homepage
# check_grafana
# check_jellyfin
# check_qbittorrent
# check_gluetun

# section "VPN"
# check_qbittorrent_vpn_ip

summary
