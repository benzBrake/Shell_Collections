#!/bin/bash
#
# RyLLMP uninstaller v1.00
# by Ryan
# Blog : http://blog.iplayloli.com
# 2018.07.03
# 
apt-get purge php5 php5-\* -y
apt-get purge mysql-server -y
apt-get purge sqlite -y
apt-get purge lighttpd -y
rm -rf /var/www /var/llmp /etc/lighttpd
echo "Uninstall LLMP compelete."