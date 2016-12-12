#!/bin/sh
echo 'Acquire::Check-Valid-Until "false";' >/etc/apt/apt.conf.d/90ignore-release-date
echo "deb http://archive.debian.org/debian-archive/debian squeeze main" > /etc/apt/sources.list
echo "deb http://archive.debian.org/debian-archive/debian squeeze-proposed-updates main" >> /etc/apt/sources.list
echo "deb http://security.debian.org squeeze/updates main" >> /etc/apt/sources.list
echo "deb http://archive.debian.org/debian-archive/debian squeeze-lts main contrib non-free" >> /etc/apt/sources.list
#install gpg key
apt-get -y install debian-archive-keyring