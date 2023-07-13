#!/bin/sh
# tcping onekey install script
# 2023.07.13
# http://doufu.ru
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
rootness() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Error:This script must be run as root!" 1>&2
        exit 1
    fi
}
program_exists() {
    ret='0'
    command -v "$1" >/dev/null 2>&1 || { ret='1'; }

    # fail on non-zero return value
    if [ "$ret" -ne 0 ]; then
        return 1
    fi

    return 0
}
rootness
if program_exists yum; then
    yum -y gcc gcc-c++ make 
elif program_exists apt-get; then
    apt-get update
    apt-get -y install wget apt-transport-https ca-certificates
    apt-get update
    apt-get -y install build-essential
elif program_exists apk; then
    apk add --virtual build-dependencies build-base gcc 
else
    echo "Do not support your system!"
    exit 1
fi
curl -sSL https://github.com/MushrooM93/tcping/raw/master/tcping.c -o /tmp/tcping.c
gcc -o /tmp/tcping /tmp/tcping.c
install -m 0775 /tmp/tcping /usr/bin/tcping
rm /tmp/tcping.c /tmp/tcping
echo "tcping install complete!"
