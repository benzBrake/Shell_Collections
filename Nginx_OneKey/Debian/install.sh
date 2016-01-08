#!/bin/bash
# Nginx Onekey Install Shell For Debian/Ubuntu
# Tested with Debian 7 32/64bit
# Script author <github-charisma@32mb.cn>
# Blog : http://blog.iplayloli.com
#1.Load config
source ~/nginx_onekey_config
test -d "$install_temp" || mkdir -p "$install_temp"
cd "$install_temp"
#2.Prepare
apt-get update || apt-get update
#2.1Handmade Clean and Streamlined Debian VPS System
case "$streamline" in
    yes)
		apt-get -y purge bind9-* xinetd samba-* nscd-* portmap sendmail-* sasl2-bin;;
    *)
		echo "skiped!";;
esac
#3.Remove apache
apt-get -y purge apache2-*
#wget --no-check-certificate https://raw.githubusercontent.com/char1sma/Shell_Collections/master/Nginx_OneKey/Debian/upgrade.sh
wget -N --no-check-certificate https://zhangzhe.32.pm/assets/nginx_onekey/upgrade.sh
chmod +x upgrade.sh
bash upgrade.sh
#4.set up nginx autostart
test -d /etc/autostart || mkdir -p /etc/autostart
cp -r -f /etc/rc.local /etc/rc.local_bak
sed -i 's/\"exit 0\"/\#/' /etc/rc.local
sed -i 's/\#exit 0/\#/' /etc/rc.local
sed -i 's/exit 0/\/usr\/local\/nginx\/sbin\/nginx \nexit 0/' /etc/rc.local