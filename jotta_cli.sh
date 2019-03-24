#!/bin/sh
# Jotta CLI onekey install script by Ryan
# 2018.11.17
# http://doufu.ru
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
function rootness {
    if [[ $EUID -ne 0 ]]; then
        echo "Error:This script must be run as root!" 1>&2
        exit 1
    fi
}
rootness
if [ ! -z $(command -v yum) ]; then
    yum repolist 2>&1 | grep Jotta > /dev/null
    if [ $? -eq 1 ]; then
        cat > /etc/yum.repos.d/JottaCLI.repo <<EOF
[jotta-cli]
name=Jottacloud CLI
baseurl=https://repo.jotta.us/redhat
gpgcheck=1
gpgkey=https://repo.jotta.us/RPM-GPG-KEY-jotta-cli
EOF
    fi
    yum -y install jotta-cli
elif [ !-z $(command -v apt-get) ]; then
    apt-get update
    apt-get -y install wget apt-transport-https ca-certificates
    wget -O - https://repo.jotta.us/public.gpg | apt-key add -
    echo "deb https://repo.jotta.us/debian debian main" | tee /etc/apt/sources.list.d/jotta-cli.list
    apt-get update
    apt-get -y install jotta-cli
else
    echo "Do not support your system!"
    exit 1
fi
if [ ! -z $(command -v systemctl) ]; then
    systemctl start jottad
    systemctl enable jottad
else
    service jottad start
    if [ ! -z $(command -v chkconfig) ]; then
        chkconfig jottad on
    else
        updaterc.d jottad defaults
    fi
fi
echo "JottaCLI install complete!"
