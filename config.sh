#!/usr/bin/env bash
# Where kubectl commands should run from
K3S_CONTROL_HOST="andrew@192.168.50.147"

# Run kubectl remotely through the control node
KUBECTL_CMD=(ssh "$K3S_CONTROL_HOST" sudo k3s kubectl)
FLUX_CMD=(ssh "$K3S_CONTROL_HOST" sudo KUBECONFIG=/etc/rancher/k3s/k3s.yaml flux)

# Cluster identity
CLUSTER_NAME="homelab-k3s"
EXPECTED_NODE_COUNT=3

# Network
INGRESS_NAMESPACE="nginx-ingress"
INGRESS_SERVICE="ingress-nginx-controller"
EXPECTED_INGRESS_IP="192.168.50.240"

# NAS / NFS
NAS_SERVER="192.168.50.227"
NAS_DOWNLOADS_PATH="/downloads"
NAS_MEDIA_PATH="/media"

QBITTORRENT_DOWNLOADS_PVC="qbittorrent-downloads"
JELLYFIN_MEDIA_PVC="jellyfin-media"

# Apps
HOMEPAGE_NAMESPACE="homepage"
HOMEPAGE_DEPLOYMENT="homepage"
HOMEPAGE_URL="https://homepage.dev-andrew.com"

GRAFANA_NAMESPACE="monitoring"
GRAFANA_DEPLOYMENT="kube-prometheus-stack-grafana"
GRAFANA_URL="https://grafana.dev-andrew.com"

JELLYFIN_NAMESPACE="jellyfin"
JELLYFIN_DEPLOYMENT="jellyfin"
JELLYFIN_URL="https://jellyfin.dev-andrew.com"

QBITTORRENT_NAMESPACE="qbittorrent"
QBITTORRENT_DEPLOYMENT="qbittorrent"
QBITTORRENT_CONTAINER="qbittorrent"
GLUETUN_CONTAINER="gluetun"
QBITTORRENT_URL="https://qbittorrent.dev-andrew.com"

# Health thresholds
GLUETUN_LOG_LOOKBACK="10m"
