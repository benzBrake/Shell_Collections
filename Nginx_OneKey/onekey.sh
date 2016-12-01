#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
NO_TEMP=/tmp/nginx_onekey
NO_CUST=no
NO_STREAM=no
NO_PMIR=http://sulinux.stanford.edu/mirrors/exim/pcre
NO_OMIR=http://mirrors.ibiblio.org/openssl/source
NO_ZMIR=http://78.108.103.11/MIRROR/ftp/png/src/history/zlib
NO_NVER=1.9.5
NO_PVER=8.37
NO_OVER=1.0.2h
NO_ZVER=1.2.7
NO_USER=www
NO_GROUP=www
NO_PATH=/etc/nginx
NO_CONF=/etc/nginx/conf/nginx.conf
NO_LOGP=/var/log/nginx
clear
# Root Check
function rootness {
if [[ $EUID -ne 0 ]]; then
   echo "Error:This script must be run as root!" 1>&2
   exit 1
fi
}
rootness
function slogan {
echo -n "
#========================================================================
# 			Nginx OneKey Install Shell
# Version :         0.21 beta1
# Script author :   Charisma<github-charisma@32mb.cn>
# Blog :            http://blog.iplayloli.com
# System Required : Centos/Debian/Ubuntu
# Project url :     https://github.com/Shell_Collections/Nginx_OneKey
#========================================================================
"
}
function startup {
	cp -r -f /etc/rc.local /etc/rc.local_bak
	AUTO='$NO_PATH/sbin/nginx'
	cat /etc/rc.local|grep 'exit 0'
	if [ $? -eq 0 ]; then
		sed -i 's/\"exit 0\"/\#/g' /etc/rc.local
		sed -i 's/\#exit 0/\#/g' /etc/rc.local
		sed -i "s#exit 0#$AUTO\nexit 0#" /etc/rc.local
	else
		echo "$AUTO">>/etc/rc.local
	fi
}
function install {
	if [ -f "$HOME/nginx_onekey_config" ]; then
		source "$HOME/nginx_onekey_config"
	else
		configure
	fi
#	Start Install
	mkdir -p "$NO_TEMP"
	install_nginx
	exit
#	Show Config Info
	$NO_PATH/sbin/nginx -V
	exit
}
function changeversion {
#	load config
	if [ -f "$HOME/nginx_onekey_config" ];then
		source $HOME/nginx_onekey_config
		read -p "# Please input the nginx version you want to install[1.9.5]:" changever
		if [ ! -n "$changever" ];then
			export NO_NVER="1.9.5"
		else
			export NO_NVER=$changever
		fi
		rm -f "$HOME/nginx_onekey_config" && write_conf
		install_nginx
	else
		echo "It seems that you don't have install Nginx_Onekey"
		exit 2;
	fi
}
function centos_nginx {
	yum update -y || yum update -y
	yum install gcc gcc-c++ make automake -y
	if [ $? -eq 0 ]; then
		echo "gcc gcc-c++ make automake installed"
	else
		yum install gcc gcc-c++ make automake -y
	fi
	if [ "$NO_CUST" = "no" ]; then
		yum install pcre pcre-devel -y
		if [ $? -eq 0 ]; then
			echo "pcre pcre-devel installed"
		else
			yum install pcre pcre-devel -y
		fi
		yum install zlib zlib-devel openssl openssl-devel -y
		if [ $? -eq 0 ]; then
			echo "zlib zlib-devel openssl openssl-devel installed"
		else
			yum install zlib zlib-devel openssl openssl-devel -y
		fi
	else
		wget "$NO_PMIR/pcre-$NO_PVER.tar.gz"
		tar -xzvf "pcre-$NO_PVER.tar.gz"
		wget "$NO_OMIR/openssl-$NO_OVER.tar.gz"
		tar -xzvf "openssl-$NO_OVER.tar.gz"
		wget "$NO_ZMIR/zlib-$NO_ZVER.tar.gz"
		tar -xzvf "zlib-$NO_ZVER.tar.gz"
	fi
}
function debian_nginx {
	apt-get update || apt-get update
	apt-get install build-essential -y
	apt-get install git-core -y
#	Handmade Clean and Streamlined Debian VPS System
	case "$NO_STREAM" in
		yes)
			apt-get -y purge bind9-* xinetd samba-* nscd-* portmap sendmail-* sasl2-bin;;
		*)
			echo "# Streamlition Skiped!";;
	esac
	# Remove apache2
	apt-get -y purge apache2-*
	
	# PCRE & OPENSSL & ZLIB
	if [ "$NO_CUST" = "no" ]; then
		apt-get install -y libpcre3 libpcre3-dev
		if [ $? -eq 0 ]; then
			echo "libpcre3 libpcre3-dev installed"
		else
			apt-get install -y libpcre3 libpcre3-dev
		fi
		apt-get install -y zlib1g zlib1g-dev openssl libssl-dev
		if [ $? -eq 0 ]; then
			echo "zlib1g zlib1g-dev openssl libssl-dev installed"
		else
			apt-get install -y zlib1g zlib1g-dev openssl libssl-dev
		fi
	else 
		wget "$NO_PMIR/pcre-$NO_PVER.tar.gz"
		tar -xzvf "pcre-$NO_PVER.tar.gz"
		wget "$NO_OMIR/openssl-$NO_OVER.tar.gz"
		tar -xzvf "openssl-$NO_OVER.tar.gz"
		wget "$NO_ZMIR/zlib-$NO_ZVER.tar.gz"
		tar -xzvf "zlib-$NO_ZVER.tar.gz"
	fi
}
function install_nginx {
	source "$HOME/nginx_onekey_config"
	test -d "$NO_TEMP" || mkdir -p "$NO_TEMP"
	test -d "$NO_LOGP" || mkdir -p "$NO_LOGP"
	cd "$NO_TEMP"
	if [ "$NO_SYST" = "Centos" ]; then
		centos_nginx
	else
		debian_nginx
	fi
	# Add user & group
	/usr/sbin/groupadd -f "$NO_GROUP"
	/usr/sbin/useradd -g "$NO_GROUP" "$NO_USER"
	# Download Nginx and Module
	wget "http://nginx.org/download/nginx-$NO_NVER.tar.gz" || wget "http://nginx.org/download/nginx-$NO_NVER.tar.gz"
	tar -xzvf "nginx-$NO_NVER.tar.gz" || tar -xzvf "nginx-$NO_NVER.tar.gz"
	wget -N --no-check-certificate https://raw.githubusercontent.com/Char1sma/Shell_Collections/master/Nginx_OneKey/ngx_http_substitutions_filter_module.tar.gz
	tar -xzvf ngx_http_substitutions_filter_module.tar.gz
	# Compile Nginx
	cd "$NO_TEMP/nginx-$NO_NVER"
	if [ "$NO_CUST" = "no" ]; then
		./configure --prefix="$NO_PATH" --conf-path="$NO_CONF" --user="$NO_USER" --group="$NO_GROUP" --error-log-path="$NO_LOGP/error.log" --http-log-path="$NO_LOGP/access.log" --pid-path=/var/run/nginx/nginx.pid --lock-path=/var/lock/nginx.lock --with-pcre-jit --with-ipv6 --with-http_ssl_module --with-http_stub_status_module --with-http_gzip_static_module --add-module="$NO_TEMP/ngx_http_substitutions_filter_module"
	else
		./configure --prefix="$NO_PATH" --conf-path="$NO_CONF" --with-pcre="$NO_TEMP/pcre-$NO_PVER" --user="$NO_USER" --group="NO_GROUP" --error-log-path="$NO_LOGP/error.log" --http-log-path="$NO_LOGP/access.log" --pid-path=/var/run/nginx/nginx.pid --lock-path=/var/lock/nginx.lock --with-ipv6 --with-http_ssl_module --with-openssl="$NO_TEMP/openssl-$NO_OVER" --with-http_stub_status_module --with-http_gzip_static_module --with-zlib="$NO_TEMP/zlib-$NO_ZVER" --add-module="$NO_TEMP/ngx_http_substitutions_filter_module"
	fi
	# Installation
	make
	if [ ! $? -eq 0 ]; then
		echo "# Compile nginx failed. Exit now!"
		rm -rf "$NO_TEMP"
		rm -rf "$HOME/nginx_onekey_config"
		exit 2
	fi
	make install
	if [ ! $? -eq 0 ]; then
		echo "# Nginx installed failed. Exit now!"
		rm -rf "$NO_TEMP"
		rm -rf "$HOME/nginx_onekey_config"
		exit 2
	fi
	startup
	echo "# nginx sbin path:$NO_PATH/sbin/nginx"
#4.Make dir and clean
	mkdir -p "$NO_LOGP"
	rm -rf "$NO_TEMP"
	exit
}
function configure {
	if [ ! -f "$HOME/nginx_onekey_config" ]; then
		question
	else
		echo "# It seems that you cofigured ever?"
		read -p "# Do you want to re-configure(Y/n):" key3
		case "$key3" in
			N/n)
				echo "# Do nothing"
				;;
			*)
				rm "$HOME/nginx_onekey_config" -rf
				question
				;;
		esac
	fi
}
function question {
	echo -n "Select which you want:
	1.Install for Debian/Ubuntu
	2.Install for Centos
Your choice:"
	read -r syst
	case "$syst" in
	1)
		NO_SYST=Debian
		;;
	2)
		NO_SYST=Centos
		;;
	*)
		echo '# Error option, quit!'
		exit 1
		;;
	esac
	read -p "# Do you want to custom installation info[y/N]:" custom
		case "$custom" in
		Y|y)
			export NO_CUST=yes
			read -p "# Do you want to Streamlined your VPS[y/N]:" stream
			case "$stream" in
			Y|y)
				export NO_STREAM=yes
				;;
			*)
				export NO_STREAM=no
				;;
			esac
			read -p "# Please input the nginx version you want to install[1.9.5]:" nginx_ver
			if [ ! "$nginx_ver" ];then
				export NO_NVER=1.9.5
			else 
				export NO_NVER="$ningx_ver"
			fi
			read -p "# Please input the pcre version you want to install[8.37]:" pcre_ver
			if [ ! -n "$pcre_ver" ];then
				export NO_PVER=8.37
			else
				export NO_PVER="$pcre_ver"
			fi
			read -p "# Please input the openssl version you want to install[1.0.2h]:" ossl_ver
			if [ ! -n "$ossl_ver" ];then
				export NO_OVER=1.0.2h
			else
				export NO_OVER="$ossl_ver"
			fi
			read -p "# Please input the zlib version you want to install[1.2.7]:" zlib_ver
			if [ ! -n "$zlib_ver" ];then
				export NO_ZVER=1.2.7
			else
				export NO_ZVER="$zlib_ver"
			fi
			;;
		*)
			echo "# Skiped!"
			;;
		esac
		write_conf
}
function write_conf {
	cat >> "$HOME/nginx_onekey_config" << EOF
NO_SYST=$NO_SYST
NO_TEMP=$NO_TEMP
NO_CUST=$NO_CUST
NO_NVER=$NO_NVER
NO_PVER=$NO_PVER
NO_STREAM=$NO_STREAM
NO_OVER=$NO_OVER
NO_ZVER=$NO_ZVER
NO_USER=$NO_USER
NO_GROUP=$NO_GROUP
NO_PATH=$NO_PATH
NO_CONF=$NO_CONF
NO_LOGP=$NO_LOGP
EOF
}
function uninstall {
read -p "Are you sure uninstall Nginx_Onekey? (y/N) " answer
	if [ -z $answer ]; then
		answer="n"
	fi
	if [ "$answer" = "y" ]; then
		source $HOME/nginx_onekey_config
		if [[ -s /etc/rc.local_bak ]]; then
			rm -f /etc/rc.local
			mv /etc/rc.local_bak /etc/rc.local
		fi
		clean
		echo "Nginx_Onekey uninstall success!"
	else
		echo "Nothing to do."
	fi
	exit
}
function clean {
	rm "$NO_TEMP" -rf
	rm "$NO_PATH" -rf
	rm "$NO_LOGP" -rf
	rm "$HOME/nginx_onekey_config" -f
	echo "# All has been done!"
}
case "$1" in
install)
	slogan
	install;;
change)
	slogan
	changeversion;;
uninstall)
	slogan
	uninstall;;
configure)
	slogan
	configure;;
clean)
	clean;;
*)
	echo "unrecognized option:"
	echo "-------------------------------------"
	echo "Usage: $0 [option]"
	echo "$0 install    install Nginx Onekey"
	echo "$0 uninstall  uninstall Nginx Onekey"
	echo "$0 change     change Nginx version"
	exit 1
	;;
esac