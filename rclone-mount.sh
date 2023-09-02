#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
#--Config Start
BIN="/usr/bin/rclone"
CONFIG="/data/rclone/rclone.conf"
LOG_PATH="/var/log/rcloned.log"
MOUNT_LIST="/data/rclone/mount.conf"
#--Config End
[ -x "$(command -v fusermount)" ] || exit 1
[ -x "$(command -v $BIN)" ] || exit 1
[ ! -f "$CONFIG" ] && exit 2
[ ! -f "$MOUNT_LIST" ] && exit 2

get_pid() {
  pgrep -f "$@" | head -n1
}

case "$1" in
start)
  while IFS= read -r line; do
    if [[ "$line" == "#"* ]]; then
      continue # Skip lines starting with #
    fi

    MOUNT_TYPE=$(echo "$line" | cut -d'=' -f1)
    REMOTE=$(echo "$line" | cut -d'=' -f2)
    MOUNT=$(echo "$line" | cut -d'=' -f3)
    EXTRA=$(echo "$line" | cut -d'=' -f4)

    # Extract USER and PASSWORD from EXTRA if MOUNT_TYPE is webdav
    if [ "$MOUNT_TYPE" = "webdav" ]; then
      USER=$(echo "$EXTRA" | cut -d':' -f1)
      PASSWORD=$(echo "$EXTRA" | cut -d':' -f2)
    fi

    PID=$(get_pid "$MOUNT")
    if [ ! -z "$PID" ]; then
      echo "$REMOTE--->$MOUNT is already mounted!"
    else
      echo "Starting $REMOTE--->$MOUNT as $MOUNT_TYPE..."

      if [ "$MOUNT_TYPE" = "webdav" ]; then
        if [ -n "$USER" ] && [ -n "$PASSWORD" ]; then
          nohup rclone --config "$CONFIG" serve webdav "$REMOTE" --vfs-cache-mode writes --cache-dir /data/tmp/rclone -vv --addr $MOUNT --user "$USER" --pass "$PASSWORD" >"$LOG_PATH" 2>&1 &
        else
          echo "WebDAV user and password are required for WebDAV type mount."
          continue # Skip mounts without user and password
        fi
      elif [ "$MOUNT_TYPE" = "local" ]; then
        nohup rclone --config "$CONFIG" mount "$REMOTE" "$MOUNT" --allow-other --allow-non-empty --umask 000 >"$LOG_PATH" 2>&1 &
      else
        echo "Invalid mount type: $MOUNT_TYPE"
        continue # Skip invalid mount types
      fi

      sleep 3
      PID=$(get_pid "$MOUNT")
      if [ -n "$PID" ]; then
        echo "$REMOTE--->$MOUNT mount success!"
      else
        echo "$REMOTE--->$MOUNT mount failed!"
      fi
    fi
  done <"$MOUNT_LIST"
  ;;
stop)
  while IFS= read -r line; do
    if [[ "$line" == "#"* ]]; then
      continue # Skip lines starting with #
    fi

    REMOTE=$(echo "$line" | cut -d'=' -f2)
    MOUNT=$(echo "$line" | cut -d'=' -f3)
    PID=$(get_pid "$MOUNT")
    [ -z "$PID" ] && echo "$REMOTE--->$MOUNT is not mounted."
    [ -n "$PID" ] && kill -9 "$PID" >/dev/null 2>&1
    [ -n "$PID" ] && umount "$MOUNT"
    [ -n "$PID" ] && echo "$REMOTE--->$MOUNT is unmounted."
  done <"$MOUNT_LIST"
  ;;
status)
  while IFS= read -r line; do
    if [[ "$line" == "#"* ]]; then
      continue # Skip lines starting with #
    fi

    REMOTE=$(echo "$line" | cut -d'=' -f2)
    MOUNT=$(echo "$line" | cut -d'=' -f3)
    PID=$(get_pid "$MOUNT")
    [ -n "$PID" ] && {
      echo "$REMOTE--->$MOUNT is already mounted!"
    } || {
      echo "$REMOTE--->$MOUNT is unmounted!"
    }
  done <"$MOUNT_LIST"
  ;;
df)
  while IFS= read -r line; do
    if [[ "$line" == "#"* ]]; then
      continue # Skip lines starting with #
    fi

    MOUNT=$(echo "$line" | cut -d'=' -f3)
    df -h | grep "$MOUNT"
  done <"$MOUNT_LIST"
  ;;
esac
exit 0
