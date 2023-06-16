#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
#--Config Start
BIN="/usr/bin/rclone"
CONFIG="/data/rclone/rclone.conf"
LOG_PATH="/var/log/rcloned.log"
MOUNT_LIST="/data/rclone/mount.conf"
#--Config End
[ -x "$(which fusermount)" ] || exit 1
[ -x "$(which fusermount3)" ] || exit 1
[ -x "$(which $BIN)" ] || exit 1
[ ! -f "$CONFIG" ] && exit 2
[ ! -f "$MOUNT_LIST" ] && exit 2

get_pid() {
  pgrep -f "$@" | head -n1
}

case "$1" in
start)
  cat "$MOUNT_LIST" | while read line; do
    REMOTE=${line//=*/}
    MOUNT=${line//*=/}
    PID=$(get_pid "$MOUNT")
    if [ ! -z "$PID" ]; then
      echo "$REMOTE--->$MOUNT is already mounted!"
    else
      echo "Starting $REMOTE--->$MOUNT..."
      mkdir -p $MOUNT
      nohup rclone mount $REMOTE $MOUNT --config $CONFIG --copy-links --no-gzip-encoding --no-check-certificate --allow-other --allow-non-empty --umask 000 --dir-cache-time 5m --vfs-cache-mode writes --buffer-size 100M --vfs-read-chunk-size 256M --vfs-read-chunk-size-limit 4G --no-modtime >$LOG_PATH 2>&1 &
      sleep 3
      PID="$(get_pid $MOUNT)"
      [ -n "$PID" ] && {
        echo "$REMOTE--->$MOUNT mount success!"
      } || {
        echo "$REMOTE--->$MOUNT mount failed!"
      }
    fi
  done
  ;;
stop)
  cat $MOUNT_LIST | while read line; do
    REMOTE=${line//=*/}
    MOUNT=${line//*=/}
    PID="$(get_pid $MOUNT)"
    [ -z "$PID" ] && echo "$REMOTE--->$MOUNT is not mount."
    [ -n "$PID" ] && kill -9 $PID >/dev/null 2>&1
    [ -n "$PID" ] && umount $MOUNT
    [ -n "$PID" ] && echo "$REMOTE--->$MOUNT is unmounted."
  done
  ;;
status)
  cat $MOUNT_LIST | while read line; do
    REMOTE=${line//=*/}
    MOUNT=${line//*=/}
    PID="$(get_pid $MOUNT)"
    [ -n "$PID" ] && {
      echo "$REMOTE--->$MOUNT is already mounted!"
    } || {
      echo "$REMOTE--->$MOUNT is unmounted!"
    }
  done
  ;;
df)
  cat $MOUNT_LIST | while read line; do
  MOUNT=${line//*=/}
    df -h | grep "$MOUNT"
  done
  ;;
esac
exit 0
