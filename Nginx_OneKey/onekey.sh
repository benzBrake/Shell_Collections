#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
clear
echo "
#========================================================================
# 			Nginx OneKey Install Shell
# Version :		0.1 alpha 2
# Script author :	Charisma<github-charisma@32mb.cn>
# Blog :		http://blog.iplayloli.com
# System Required :	Debian
# Project url :		https://github.com/Shell_Collections/Nginx_OneKey
#========================================================================
"
function install {
#	root access check
	rootness
#	install Nginx Onekey
	echo -n "Select which you want:
	1.Install for Debian/Ubuntu
	2.Install for Centos
Your choice:"
	read key
	if [ $key = "1" ];then
		system="Debian"
	elif [ $key = "1" ];then
		system="Centos"
	else
		echo '# Error option,exit!'
		exit 1
	fi
	#	load config
	configure
	mkdir -p $install_temp
	cd $install_temp

	wget --no-check-certificate https://raw.githubusercontent.com/Char1sma/Shell_Collections/master/Nginx_OneKey/$system/install.sh	
#	wget --no-check-certificate https://zhangzhe.32.pm/assets/nginx_onekey/install.sh
	chmod +x install.sh
	bash install.sh
	exit
#	Show Config Info And Reload
	$install_path/sbin/nginx -V
	$install_path/sbin/nginx -s reload
	exit
}
function upnginx {
#	root access check
	rootness
#	load config
	configure
#	upgrade Nginx to any version
	mkdir -p $install_temp
	cd $install_temp
	wget --no-check-certificate https://raw.githubusercontent.com/Char1sma/Shell_Collections/master/Nginx_OneKey/$system/upgrade.sh
#	wget --no-check-certificate https://zhangzhe.32.pm/assets/nginx_onekey/upgrade.sh
	chmod +x upgrade.sh
	bash upgrade.sh
	exit
}
function configure {
	if [ ! -f "~/nginx_onekey_config" ]; then 
		read -p "Do you want to custom installation info?(y/N)" custom
		case $custom in
			Y/y)
				read -p "Do you want to Streamlined your VPS ?(y/N):" stream
				case $stream in
					Y|y)
						streamline="yes";;
					*)
						streamline="no";;
				esac
				read -p "Do you want to stream[1.9.5]:" nginx_ver
				if [ -n $nginx_ver ];then
					nginx_ver="1.9.5"
				fi
				read -p "Please input the nginx version you want to install[1.9.5]:" nginx_ver
				if [ -n $nginx_ver ];then
					nginx_ver="1.9.5"
				fi
				read -p "Please input the pcre version you want to install[8.37]:" pcre_ver
				if [ -n $pcre_ver ];then
					pcre_ver="8.37"
				fi
				read -p "Please input the openssl version you want to install[1.0.1q]:" ossl_ver
				if [ -n $ossl_ver ];then
					ossl_ver="1.0.1q"
				fi
				read -p "Please input the openssl version you want to install[1.2.7]:" zlib_ver
				if [ -n $zlib_ver ];then
					zlib_ver="1.2.7"
				fi
			*)
				nginx_ver="1.9.5"
				pcre_ver="8.37"
				ossl_ver="1.0.1q"
				zlib_ver="1.2.7"
		esac
		cat >> ~/nginx_onekey_config << EOF
install_temp=/tmp/nginx_onekey
nginx_ver=$nginx_ver
pcre_ver=$pcre_ver
streamline=$streamline
compile_poz=yes
pcre_mirror=http://sulinux.stanford.edu/mirrors/exim/pcre
ossl_ver=$ossl_ver
ossl_mirror=http://mirrors.ibiblio.org/openssl/source
zlib_ver=$zlib_ver
zlib_mirror=http://78.108.103.11/MIRROR/ftp/png/src/history/zlib
mirror=https://raw.githubusercontent.com/char1sma/Shell_Collections/master/Nginx_OneKey/Mirrors
n_user=www
n_group=www
install_path=/usr/local/nginx
conf_path=$install_path/conf/nginx.conf
log_path=/var/log/nginx
EOF
	fi
	. ~/nginx_onekey_config
	echo "Config loaded!"
}
function rootness {
if [[ $EUID -ne 0 ]]; then
   echo "Error:This script must be run as root!" 1>&2
   exit 1
fi
}
case $1 in
	install)
		install;;
	upgrade)
		upnginx;;
	uninstall)
		echo 'not avaliable now';;
	configure)
		configure;;
	*)
		echo "unrecognized option:"
		echo "-------------------------------------"
		echo "Usage: $0 [option]"
		echo "$0 install	install Nginx Onekey"
		echo "$0 uninstall	uninstall Nginx Onekey"
		echo "$0 upgrade	uninstall Nginx Onekey"
		echo "$0 configure	custom installation info"
		exit 1
esac