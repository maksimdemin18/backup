#!/usr/bin/env bash
set -euo pipefail

PATH=/usr/sbin:/usr/bin:/sbin:/bin

SRC="${SRC:-$HOME/}"
DEST_ROOT="${DEST_ROOT:-backupuser@backuphost:/srv/rsync-snapshots/$HOSTNAME/$USER}"
KEEP="${KEEP:-5}"
SSH_OPTS="${SSH_OPTS:--o BatchMode=yes}"
LOG_TAG="rsync_snapshot_backup"

is_remote=0
if [[ "$DEST_ROOT" == *":"* ]]; then
  is_remote=1
  REMOTE_HOST="${DEST_ROOT%%:*}"
  REMOTE_PATH="${DEST_ROOT#*:}"
fi

TS="$(date +%F_%H-%M-%S)"

mkdir_remote() { ssh $SSH_OPTS "$REMOTE_HOST" "mkdir -p '$REMOTE_PATH/$TS' '$REMOTE_PATH'"; }
mkdir_local()  { mkdir -p "$DEST_ROOT/$TS" "$DEST_ROOT"; }

set_latest_remote() { ssh $SSH_OPTS "$REMOTE_HOST" "cd '$REMOTE_PATH' && ln -sfn '$TS' latest"; }
set_latest_local()  { ( cd "$DEST_ROOT" && ln -sfn "$TS" latest ); }

latest_exists_remote() { ssh $SSH_OPTS "$REMOTE_HOST" "test -e '$REMOTE_PATH/latest'"; }
latest_exists_local()  { test -e "$DEST_ROOT/latest"; }

cleanup_remote() {
  ssh $SSH_OPTS "$REMOTE_HOST" "bash -lc '
    set -euo pipefail
    cd "'\"$REMOTE_PATH\"'"
    KEEP="'\"$KEEP\"'"
    mapfile -t snaps < <(ls -1d [0-9][0-9][0-9][0-9]-* 2>/dev/null | sort || true)
    cnt=\${#snaps[@]}
    if (( cnt > KEEP )); then
      del=\$((cnt-KEEP))
      for ((i=0; i<del; i++)); do rm -rf \"\${snaps[i]}\"; done
    fi
  '"
}

cleanup_local() {
  cd "$DEST_ROOT"
  mapfile -t snaps < <(ls -1d [0-9][0-9][0-9][0-9]-* 2>/dev/null | sort || true)
  cnt=${#snaps[@]}
  if (( cnt > KEEP )); then
    del=$((cnt-KEEP))
    for ((i=0; i<del; i++)); do rm -rf "${snaps[i]}"; done
  fi
}

if (( is_remote )); then
  mkdir_remote
  DEST="$REMOTE_HOST:$REMOTE_PATH/$TS/"
else
  mkdir_local
  DEST="$DEST_ROOT/$TS/"
fi

link_dest_opt=()
if (( is_remote )); then
  latest_exists_remote && link_dest_opt+=("--link-dest=../latest") || true
else
  latest_exists_local && link_dest_opt+=("--link-dest=../latest") || true
fi

RSYNC_OPTS=( -a --delete --numeric-ids --stats )

set +e
output="$(rsync "${RSYNC_OPTS[@]}" "${link_dest_opt[@]}" "$SRC" "$DEST" 2>&1)"
rc=$?
set -e

if [[ $rc -eq 0 ]]; then
  logger -t "$LOG_TAG" "OK: SRC=$SRC DEST_ROOT=$DEST_ROOT SNAP=$TS"
  if (( is_remote )); then
    set_latest_remote
    cleanup_remote
  else
    set_latest_local
    cleanup_local
  fi
else
  logger -t "$LOG_TAG" "FAIL(rc=$rc): SRC=$SRC DEST_ROOT=$DEST_ROOT SNAP=$TS"
fi

printf '%s\n' "$output"
exit $rc
