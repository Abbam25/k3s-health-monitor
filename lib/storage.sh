#!/usr/bin/env bash

check_pvc_bound() {
  local namespace="$1"
  local pvc="$2"
  local phase

  if ! k get pvc "$pvc" -n "$namespace" >/dev/null 2>&1; then
    fail "PVC $namespace/$pvc not found"
    return 1
  fi

  phase="$(k get pvc "$pvc" -n "$namespace" -o jsonpath='{.status.phase}' 2>/dev/null)"

  if [ "$phase" = "Bound" ]; then
    pass "PVC $namespace/$pvc is Bound"
    return 0
  else
    fail "PVC $namespace/$pvc is $phase, expected Bound"
    return 1
  fi
}

check_qbittorrent_downloads() {
  local test_file="$NAS_DOWNLOADS_PATH/.k3s-healthcheck"

  check_pvc_bound "$QBITTORRENT_NAMESPACE" "$QBITTORRENT_DOWNLOADS_PVC" || return

  if ! k exec -n "$QBITTORRENT_NAMESPACE" "deploy/$QBITTORRENT_DEPLOYMENT" \
    -c "$QBITTORRENT_CONTAINER" -- df -h "$NAS_DOWNLOADS_PATH" >/dev/null 2>&1; then
    fail "qBittorrent downloads path is not mounted at $NAS_DOWNLOADS_PATH"
    echo "       Check NFS mount, PVC, and qBittorrent pod events."
    return
  fi

  if ! k exec -n "$QBITTORRENT_NAMESPACE" "deploy/$QBITTORRENT_DEPLOYMENT" \
    -c "$QBITTORRENT_CONTAINER" -- touch "$test_file" >/dev/null 2>&1; then
    fail "qBittorrent cannot write to $NAS_DOWNLOADS_PATH"
    echo "       Mounted, but write failed. Check NFS permissions and Mac export ownership."
    return
  fi

  if ! k exec -n "$QBITTORRENT_NAMESPACE" "deploy/$QBITTORRENT_DEPLOYMENT" \
    -c "$QBITTORRENT_CONTAINER" -- rm -f "$test_file" >/dev/null 2>&1; then
    warn "qBittorrent wrote test file but could not delete $test_file"
    return
  fi

  pass "qBittorrent downloads storage is mounted and writable at $NAS_DOWNLOADS_PATH"
}

check_jellyfin_media() {
  check_pvc_bound "$JELLYFIN_NAMESPACE" "$JELLYFIN_MEDIA_PVC" || return

  if ! k exec -n "$JELLYFIN_NAMESPACE" "deploy/$JELLYFIN_DEPLOYMENT" \
    -- df -h "$NAS_MEDIA_PATH" >/dev/null 2>&1; then
    fail "Jellyfin media path is not mounted at $NAS_MEDIA_PATH"
    echo "       Check NFS mount, PVC, and Jellyfin pod events."
    return
  fi

  if ! k exec -n "$JELLYFIN_NAMESPACE" "deploy/$JELLYFIN_DEPLOYMENT" \
    -- ls -la "$NAS_MEDIA_PATH" >/dev/null 2>&1; then
    fail "Jellyfin cannot read $NAS_MEDIA_PATH"
    echo "       Mounted, but read failed. Check NFS permissions."
    return
  fi

  pass "Jellyfin media storage is mounted and readable at $NAS_MEDIA_PATH"
}
