#!/usr/bin/env bash

# error codes
# 0 - exited without problems
# 1 - some unexpected error occurred
# 2 - OS not supported by this script
# 3 - installed version of clouddrive2 is up to date
# 4 - supported unzip tools are not available
# 5 - root required

set -e

#exit if current user is not root
if [[ $(id -u) -ne 0 ]]; then
    echo Current user is not root
    exit 5
fi

#exit when os is not openwrt
OS_name=$(cat /etc/*release | awk -F'=' '{if($1~/^ID/) print $2}' | head -n 1)
if ! echo "$OS_name" | grep -q "openwrt"; then
    echo "Only support openwrt"
    exit 2
fi

#detect the platform
OS='linux'
OS_type="$(uname -m)"
case $OS_type in
x86_64 | amd64)
    OS_type='x86_64'
    ;;
i?86 | x86)
    echo 'OS arch not supported'
    exit 2
    ;;
arm*)
    OS_type='arm'
    ;;
aarch64)
    OS_type='aarch64'
    ;;
*)
    echo 'OS type not supported'
    exit 2
    ;;
esac

# install requirements
if ! which fusermount >&-; then
    opkg update
    opkg install fuse-utils
fi
if ! which fusermount3 >&-; then
    opkg update
    opkg install fuse3-utils
fi

# get release info
RELEASE_INFO=$(curl -sL "https://api.github.com/repos/cloud-fs/cloud-fs.github.io/releases")
LATEST_TAG=$(echo "$RELEASE_INFO" | grep tag_name | head -n 1 | cut -d '"' -f 4)
LATEST_VERSION=$(echo "$RELEASE_INFO" | grep name | grep -v tgz | grep -v tag | grep -v upload | head -n 1 | cut -d '"' -f 4)

# exit when the latest version is installed
if [ -f /opt/clouddrive/clouddrive ] then
    if /opt/clouddrive/clouddrive --version | grep ${LATEST_VERSION/V/} >&-; then
        printf "clouddrive %s already installed\n" "$LATEST_VERSION"
        exit 3
    fi
fi

# download release
[ ! -d /opt ] && mkdir /opt
[ -f /opt/clouddrive.tgz ] && rm /opt/clouddrive.tgz
DOWNLOAD_LINK=$(echo "$RELEASE_INFO" | grep "$LATEST_TAG" | grep "$OS" | grep "$OS_type" | head -n 1 | cut -d '"' -f 4)
if ! echo "$DOWNLOAD_LINK" | grep -q http; then
    printf "No release found for %s %s" "$OS" "$OS_type"
    exit 1
fi
curl -sL "$DOWNLOAD_LINK" -o /opt/clouddrive.tgz

# unzip release
tar zxvf /opt/clouddrive.tgz -C /opt
[ -f /opt/clouddrive.tgz ] && rm /opt/clouddrive.tgz
[ ! -d /opt/clouddrive.new ] && rm -rf /opt/clouddrive.new
EXTRACT_DIR=$(ls /opt/ | grep clouddrive- | head -n 1)
if [ -z "$EXTRACT_DIR" ]; then
    printf "Extract compressed file failed!"
    exit 1
fi

# close clouddrive
set +e
ps -ef | grep /opt/clouddrive/clouddrive | grep -v grep | awk '{print $2}' | xargs kill -9
set -e

if [ -d /opt/clouddrive ]; then
    rm /opt/clouddrive/clouddrive
    install 0755 /opt/$EXTRACT_DIR/clouddrive /opt/clouddrive/clouddrive
else
    mkdir /opt/clouddrive
    cp -r /opt/$EXTRACT_DIR/* /opt/clouddrive
    rm -rf /opt/$EXTRACT_DIR
fi


chmod +x /opt/clouddrive/clouddrive

cat >/etc/init.d/clouddrive <<'EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=15
USE_PROCD=1

SERVICE=clouddrive
PROGDIR=/opt/clouddrive/clouddrive

start_service() {
    procd_open_instance
    procd_set_param command "$PROGDIR"
    procd_set_param respawn
    procd_close_instance
    echo "$SERVICE" started
}

stop_service() {
    echo stop "$SERVICE"
    pgrep $PROGDIR | xargs kill -9
}
EOF

chmod +x /etc/init.d/clouddrive
service clouddrive enable
# 如果有已经运行的实例，终结之
pgrep clouddrive | xargs kill -9
service clouddrive start

echo "server on: http://$(ip -4 route | awk '{print $NF}' | tail -1):19798"
echo 'start service: service clouddrive start'
echo 'stop service: service clouddrive stop'
