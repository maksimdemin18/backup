#!/usr/bin/env bash
set -euo pipefail

PATH=/usr/sbin:/usr/bin:/sbin:/bin

DEST_ROOT="${DEST_ROOT:-backupuser@backuphost:/srv/rsync-snapshots/$HOSTNAME/$USER}"
RESTORE_DEST="${RESTORE_DEST:-$HOME/}"
SSH_OPTS="${SSH_OPTS:--o BatchMode=yes}"

is_remote=0
if [[ "$DEST_ROOT" == *":"* ]]; then
  is_remote=1
  REMOTE_HOST="${DEST_ROOT%%:*}"
  REMOTE_PATH="${DEST_ROOT#*:}"
fi

list_snaps() {
  if (( is_remote )); then
    ssh $SSH_OPTS "$REMOTE_HOST" "cd '$REMOTE_PATH' && ls -1d [0-9][0-9][0-9][0-9]-* 2>/dev/null | sort" || true
  else
    ( cd "$DEST_ROOT" && ls -1d [0-9][0-9][0-9][0-9]-* 2>/dev/null | sort ) || true
  fi
}

mapfile -t snaps < <(list_snaps)
if (( ${#snaps[@]} == 0 )); then
  echo "Не найдено ни одной резервной копии в DEST_ROOT=$DEST_ROOT" >&2
  exit 2
fi

echo "Доступные резервные копии:"
for i in "${!snaps[@]}"; do
  printf '  [%d] %s\n' "$i" "${snaps[$i]}"
done

echo -n "Выберите номер резервной копии для восстановления: "
read -r idx

if ! [[ "$idx" =~ ^[0-9]+$ ]] || (( idx < 0 || idx >= ${#snaps[@]} )); then
  echo "Некорректный выбор" >&2
  exit 3
fi

snap="${snaps[$idx]}"

if (( is_remote )); then
  SRC="$REMOTE_HOST:$REMOTE_PATH/$snap/"
else
  SRC="$DEST_ROOT/$snap/"
fi

rsync -a --delete --numeric-ids --stats "$SRC" "$RESTORE_DEST"
echo "Готово: восстановлено из $snap в $RESTORE_DEST"
