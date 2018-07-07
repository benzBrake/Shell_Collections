#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
NO_NVER=1.9.5
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
# Version :         0.24
# Script author :   benzBrake<github-benzbrake@woai.ru>
# Blog :            http://blog.iplayloli.com
# System Required : Centos/Debian/Ubuntu
# Project url :     https://github.com/benzBrake/Shell_Collections/Nginx_OneKey
#========================================================================
" 1>&2
}
function startup {
#	Start Nginx
	if [ -n "$(command -v systemctl)" ]; then
		systemctl start nginx.service
	else
		/etc/init.d/nginx start
	fi
}
function install {
#	load config
	if [ -f "$HOME/nginx_onekey_config" ]; then
		source "$HOME/nginx_onekey_config"
	else
		configure
	fi
	
#	Start Install
	mkdir -p "$NO_TEMP"
	install_Nginx
	startup
#	Show Config Info
	cd "$NO_PATH/sbin/"
	./nginx -V
	exit
}
function change_Version {
#	load config
	if [ -f "$HOME/nginx_onekey_config" ];then
		source $HOME/nginx_onekey_config
		read -p "# Please input the nginx version you want to install[1.9.5]:" changever
		if [ -z "$changever" ];then
			export NO_NVER="1.9.5"
		else
			export NO_NVER=$changever
		fi
		rm -f "$HOME/nginx_onekey_config" && write_Conf
		install_Nginx
	else
		echo "It seems that you don't have install Nginx_Onekey"
		exit 2;
	fi
}
function centos_Prepare {
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
function debian_Prepare {
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
	
	# PCRE & OPENSSL & ZLIB
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
function install_Nginx {
#	load config
	source "$HOME/nginx_onekey_config"
	test -d "$NO_TEMP" || mkdir -p "$NO_TEMP"
	test -d "$NO_LOGP" || mkdir -p "$NO_LOGP"

#	Install required packages
	if [ -n "$(command -v yum)" ]; then
		centos_Prepare
	else
		debian_Prepare
	fi

#	Add user & group
	/usr/sbin/groupadd -f "$NO_GROUP"
	/usr/sbin/useradd -g "$NO_GROUP" "$NO_USER"
	
#	Download Nginx and Module
	cd "$NO_TEMP"
	wget "http://nginx.org/download/nginx-$NO_NVER.tar.gz"
	tar -xzvf "nginx-$NO_NVER.tar.gz" || tar -xzvf "nginx-$NO_NVER.tar.gz"
	NO_OPTS=""
	! test -z "$NO_MODULES" && test -d "$NO_MODULES" && {
		for line in $(ls -F $NO_MODULES | grep '/$')
		do
			NO_OPTS="$NO_OPTS --add-module=$NO_MODULES/$(echo $line | sed 's#/$##')"
		done
	}

#	Compile Nginx
	cd "$NO_TEMP/nginx-$NO_NVER"
	./configure --prefix="$NO_PATH" --conf-path="$NO_CONF" --user="$NO_USER" --group="$NO_GROUP" --error-log-path="$NO_LOGP/error.log" --http-log-path="$NO_LOGP/access.log" --pid-path=/var/run/nginx.pid --lock-path=/var/lock/nginx.lock --with-pcre-jit --with-ipv6 --with-http_ssl_module --with-http_stub_status_module --with-http_gzip_static_module $NO_OPTS

#	Installation
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
	install_Service
	echo "# nginx sbin path:$NO_PATH/sbin/nginx"
#	Make dir and clean
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
	write_Conf
}
function write_Conf {
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
function install_Service {
#	Install nginx auto startup service.
	if [ -n "$(command -v systemctl)" ]; then
		wget --no-check-certificate https://github.com/benzBrake/Shell_Collections/raw/master/Nginx_OneKey/nginx.service -O /lib/systemd/system/nginx.service
		sed -i "s@#pid.*@pid     /var/run/nginx.pid;@" $NO_CONF
		systemctl daemon-reload
		systemctl enable nginx.service
	elif [ -n "$(command -v apt-get)" ]; then
		wget --no-check-certificate https://github.com/benzBrake/Shell_Collections/raw/master/Nginx_OneKey/nginx_debian -O /etc/init.d/nginx
		chmod +x /etc/init.d/nginx
		update-rc.d nginx defualts
	elif [ -n "$(command -v yum)" ]; then
		wget --no-check-certificate https://github.com/benzBrake/Shell_Collections/raw/master/Nginx_OneKey/nginx_rhel -O /etc/init.d/nginx
		chmod +x /etc/init.d/nginx
		chkconfig nginx enable
	fi
}
function uninstall_Service {
#	Remove nginx auto startup service.
	if [ -n "$(command -v systemctl)" ]; then
		systemctl stop nginx.service
		systemctl disable nginx.service
		rm -rf /lib/systemd/system/nginx.service
		systemctl daemon-reload
		systemctl reset-failed
	elif [ -n "$(command -v apt-get)" ]; then
		service nginx stop
		update-rc.d nginx remove
		rm -rf /etc/init.d/nginx
	elif [ -n "$(command -v yum)" ]; then
		service nginx stop
		chkconfig nginx disable
		rm -rf /etc/init.d/nginx
	fi
}
function uninstall {
	read -p "Are you sure uninstall Nginx_Onekey? (y/N) " answer
	if [ -z $answer ]; then
		answer="n"
	fi
	if [ "$answer" = "y" ]; then
		uninstall_Service
		clean
		echo "Nginx_Onekey uninstall success!"
	else
		echo "Nothing to do."
	fi
	exit
}
function clean {
	rm -rf /var/log/nginx /var/run/nginx.pid
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
	change_Version;;
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
