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
  check_pvc_bound "$QBITTORRENT_NAMESPACE" "$QBITTORRENT_DOWNLOADS_PVC" || return

  if k exec -n "$QBITTORRENT_NAMESPACE" "deploy/$QBITTORRENT_DEPLOYMENT" \
    -c "$QBITTORRENT_CONTAINER" -- sh -c \
    "df -h '$NAS_DOWNLOADS_PATH' >/dev/null && timeout 10 sh -c 'touch $NAS_DOWNLOADS_PATH/.healthcheck && rm -f $NAS_DOWNLOADS_PATH/.healthcheck'" >/dev/null 2>&1; then
    pass "qBittorrent downloads storage is mounted and writable at $NAS_DOWNLOADS_PATH"
  else
    fail "qBittorrent downloads storage failed read/write test at $NAS_DOWNLOADS_PATH"
    echo "       Check Mac NFS export, external drive mount, and qBittorrent pod events."
  fi
}

check_jellyfin_media() {
  check_pvc_bound "$JELLYFIN_NAMESPACE" "$JELLYFIN_MEDIA_PVC" || return

  if k exec -n "$JELLYFIN_NAMESPACE" "deploy/$JELLYFIN_DEPLOYMENT" -- sh -c \
    "df -h '$NAS_MEDIA_PATH' >/dev/null && timeout 10 ls -la '$NAS_MEDIA_PATH' >/dev/null" >/dev/null 2>&1; then
    pass "Jellyfin media storage is mounted and readable at $NAS_MEDIA_PATH"
  else
    fail "Jellyfin media storage failed read test at $NAS_MEDIA_PATH"
    echo "       Check Mac NFS export, external drive mount, and Jellyfin pod events."
  fi
}
