#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
NO_TEMP=/tmp/nginx_onekey
NO_STREAM=no
NO_USER=www
NO_GROUP=www
NO_PATH=/etc/nginx
NO_CONF=/etc/nginx/conf/nginx.conf
NO_LOGP=/var/log/nginx
NO_MODULES=/usr/src/nginx/modules
clear
# Root Check
[[ $EUID -ne 0 ]] && { echo "Error:This script must be run as root!" 1>&2; exit 1; }
function slogan {
echo -n "
#========================================================================
# 			Nginx OneKey Install Shell
# Version :         0.23
# Script author :   benzBrake<github-benzbrake@woai.ru>
# Blog :            http://blog.iplayloli.com
# System Required : Centos/Debian/Ubuntu
# Project url :     https://github.com/benzBrake/Shell_Collections/Nginx_OneKey
#========================================================================
" 1>&2
}
function startup {
	cp -r -f /etc/rc.local /etc/rc.local_bak
	AUTO="$NO_PATH/sbin/nginx"
	cat /etc/rc.local|grep "$AUTO"
	if [ $? -ne 0 ]; then
		sed -i "s#exit 0#$AUTO\nexit 0#" /etc/rc.local
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
#	Show Config Info
	cd "$NO_PATH/sbin/"
	./nginx
	./nginx -V
	exit
}
function changeversion {
#	load config
	if [ -f "$HOME/nginx_onekey_config" ];then
		source $HOME/nginx_onekey_config
		read -p "# Please input the nginx version you want to install[1.9.5]:" changever
		if [ -z "$changever" ];then
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
function centos_prepare {
	yum install gcc gcc-c++ make automake -y
	if [ $? -eq 0 ]; then
		echo "gcc gcc-c++ make automake installed"
	else
		yum install gcc gcc-c++ make automake -y
	fi

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
}
function debian_prepare {
	apt-get update -y
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
	
	# PCRE & OPENSSL & ZLIBn
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
}
function install_nginx {
	source "$HOME/nginx_onekey_config"
	test -d "$NO_TEMP" || mkdir -p "$NO_TEMP"
	test -d "$NO_LOGP" || mkdir -p "$NO_LOGP"
	cd "$NO_TEMP"
	if [ -n "$(command -v yum)" ]; then
		centos_prepare
	else
		debian_prepare
	fi
	# Add user & group
	/usr/sbin/groupadd -f "$NO_GROUP"
	/usr/sbin/useradd -g "$NO_GROUP" "$NO_USER"
	# Download Nginx and Module
	wget "http://nginx.org/download/nginx-$NO_NVER.tar.gz"
	tar -xzvf "nginx-$NO_NVER.tar.gz" || tar -xzvf "nginx-$NO_NVER.tar.gz"
	NO_OPTS=""
	! test-z "$NO_MODULES" && test -d "$NO_MODULES" && {
		for line in $(ls -F $NO_MODULES | grep '/$')
		do
			NO_OPTS="$NO_OPTS --add-module=$NO_MODULES/$(echo $line | sed 's#/$##')"
		done
	}
	# Compile Nginx
	cd "$NO_TEMP/nginx-$NO_NVER"
	./configure --prefix="$NO_PATH" --conf-path="$NO_CONF" --user="$NO_USER" --group="$NO_GROUP" --error-log-path="$NO_LOGP/error.log" --http-log-path="$NO_LOGP/access.log" --pid-path=/var/run/nginx/nginx.pid --lock-path=/var/lock/nginx.lock --with-pcre-jit --with-ipv6 --with-http_ssl_module --with-http_stub_status_module --with-http_gzip_static_module $NO_OPTS
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
	write_conf
}
function write_conf {
	cat >> "$HOME/nginx_onekey_config" << EOF
NO_TEMP=$NO_TEMP
NO_NVER=$NO_NVER
NO_STREAM=$NO_STREAM
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
