#!/usr/bin/env bash

check_deployment_ready() {
  local name="$1"
  local namespace="$2"
  local deployment="$3"

  if ! k get deployment "$deployment" -n "$namespace" >/dev/null 2>&1; then
    fail "$name deployment $namespace/$deployment not found"
    return 1
  fi

  local desired
  local available

  desired="$(k get deployment "$deployment" -n "$namespace" -o jsonpath='{.status.replicas}' 2>/dev/null)"
  available="$(k get deployment "$deployment" -n "$namespace" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"

  desired="${desired:-0}"
  available="${available:-0}"

  if [ "$desired" -gt 0 ] && [ "$available" -eq "$desired" ]; then
    pass "$name deployment Ready: $available/$desired"
    return 0
  else
    fail "$name deployment not Ready: $available/$desired"
    echo "       Run: kubectl get pods -n $namespace"
    return 1
  fi
}

check_homepage() {
  check_deployment_ready "Homepage" "$HOMEPAGE_NAMESPACE" "$HOMEPAGE_DEPLOYMENT"
}

check_grafana() {
  check_deployment_ready "Grafana" "$GRAFANA_NAMESPACE" "$GRAFANA_DEPLOYMENT"
}

check_jellyfin() {
  check_deployment_ready "Jellyfin" "$JELLYFIN_NAMESPACE" "$JELLYFIN_DEPLOYMENT"
}

check_qbittorrent() {
  check_deployment_ready "qBittorrent" "$QBITTORRENT_NAMESPACE" "$QBITTORRENT_DEPLOYMENT" || return

  local pod
  pod="$(k get pod -n "$QBITTORRENT_NAMESPACE" -l app=qbittorrent -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"

  if [ -z "$pod" ]; then
    fail "qBittorrent pod not found"
    return
  fi

  local container_statuses
  container_statuses="$(k get pod "$pod" -n "$QBITTORRENT_NAMESPACE" \
    -o jsonpath='{range .status.containerStatuses[*]}{.name}{"="}{.ready}{" "}{end}' 2>/dev/null)"

  if echo "$container_statuses" | grep -q "$QBITTORRENT_CONTAINER=true" && \
     echo "$container_statuses" | grep -q "$GLUETUN_CONTAINER=true"; then
    pass "qBittorrent containers Ready: $container_statuses"
  else
    fail "qBittorrent containers not Ready: $container_statuses"
    echo "       Run: kubectl describe pod -n $QBITTORRENT_NAMESPACE $pod"
  fi

  if k exec -n "$QBITTORRENT_NAMESPACE" "deploy/$QBITTORRENT_DEPLOYMENT" \
    -c "$QBITTORRENT_CONTAINER" -- wget -q --spider --timeout=10 "http://127.0.0.1:8080" >/dev/null 2>&1; then
    pass "qBittorrent Web UI reachable inside pod"
  else
    fail "qBittorrent Web UI not reachable inside pod"
    echo "       qBittorrent container is running, but localhost:8080 did not respond."
  fi
}

check_gluetun() {
  local logs
  local bad_logs

  if ! k logs -n "$QBITTORRENT_NAMESPACE" "deploy/$QBITTORRENT_DEPLOYMENT" \
    -c "$GLUETUN_CONTAINER" --since="$GLUETUN_LOG_LOOKBACK" >/tmp/gluetun-healthcheck.log 2>/dev/null; then
    fail "Could not read Gluetun logs"
    return
  fi

  logs="$(cat /tmp/gluetun-healthcheck.log)"

  bad_logs="$(echo "$logs" | grep -Ei 'restarting VPN because it failed to pass the healthcheck|lookup .* i/o timeout|wireguard connection is not working|operation not permitted' || true)"

  rm -f /tmp/gluetun-healthcheck.log

  if [ -z "$bad_logs" ]; then
    pass "Gluetun logs clean for last $GLUETUN_LOG_LOOKBACK"
  else
    fail "Gluetun VPN health issue detected in last $GLUETUN_LOG_LOOKBACK:"
    echo "$bad_logs" | tail -10 | sed 's/^/       /'
    echo "       Suggested: check Proton endpoint, DNS_ADDRESS, DOT, and WIREGUARD_MTU."
  fi
}
