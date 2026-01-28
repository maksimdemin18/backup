#!/usr/bin/env bash
set -euo pipefail

PATH=/usr/sbin:/usr/bin:/sbin:/bin

SRC="${SRC:-$HOME/}"
DEST="${DEST:-/tmp/backup/}"
EXCLUDE_HIDDEN_DIRS="${EXCLUDE_HIDDEN_DIRS:-1}"

LOG_TAG="rsync_home_backup"
LOG_FILE="${LOG_FILE:-/tmp/rsync_backup.log}"
LOCK_FILE="${LOCK_FILE:-/tmp/${LOG_TAG}.lock}"

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "$(date -Is) Пропускаем: уже запущено" >> "$LOG_FILE"
  exit 0
fi

RSYNC_OPTS=(
  -a
  --delete
  --checksum
  --human-readable
  --stats
)

FILTER_OPTS=()
if [[ "$EXCLUDE_HIDDEN_DIRS" == "1" ]]; then
  FILTER_OPTS+=("--filter=- .*/")
fi

start_ts="$(date -Is)"
msg_base="SRC=$SRC DEST=$DEST"

mkdir -p "$DEST"

set +e
output="$(rsync "${RSYNC_OPTS[@]}" "${FILTER_OPTS[@]}" "$SRC" "$DEST" 2>&1)"
rc=$?
set -e

if [[ $rc -eq 0 ]]; then
  logger -t "$LOG_TAG" "OK: $msg_base"
  echo "$start_ts OK: $msg_base" >> "$LOG_FILE"
else
  logger -t "$LOG_TAG" "FAIL(rc=$rc): $msg_base"
  echo "$start_ts FAIL(rc=$rc): $msg_base" >> "$LOG_FILE"
fi

{
  echo "----- ${start_ts} rsync output (rc=$rc) -----"
  echo "$output"
  echo
} >> "$LOG_FILE"

exit $rc
