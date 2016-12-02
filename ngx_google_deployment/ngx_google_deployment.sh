#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
function rootness {
	if [[ $EUID -ne 0 ]]; then
		echo "Error:This script must be run as root!" 1>&2
		exit 1
	fi
}
rootness
function slogan {
clear
echo -n "#========================================================================
#                   ngx_google_deployment_mod_C Install Shell
# Version :         0.1 beta2
# Script author :   Charisma<github-charisma@32mb.cn>
# Blog :            http://blog.iplayloli.com
# System Required : Centos/Debian/Ubuntu
# Project url :https://github.com/Shell_Collections/ngx_google_deployment
# Thanks To :       arnofeng<http://github.com/arnofeng>
#========================================================================"
}
function install {
	kill80
	if [ -f "$HOME/nginx_onekey_config" ]; then
		source "$HOME/nginx_onekey_config"
	else
		configure
	fi
#	Install nginx
	wget -N --no-check-certificate https://raw.githubusercontent.com/Char1sma/Shell_Collections/master/Nginx_OneKey/onekey.sh
	bash onekey.sh install
#	Download nginx config file
	source "$HOME/nginx_onekey_config"
	cd "$NO_PATH"
	test -d "$NO_PATH/conf" || mkdir "$NO_PATH/conf"
	cd "$NO_PATH/conf"
	if [ -f "./nginx.conf" ]; then
		mv nginx.conf nginx.conf.bak
	fi
	wget -N --no-check-certificate https://raw.githubusercontent.com/Char1sma/Shell_Collections/master/ngx_google_deployment/nginx.conf
	sed -i "s/g.doufu.ru/$NO_SEARCH/" nginx.conf
	sed -i "s/x.doufu.ru/$NO_SCHOLAR/" nginx.conf
	test -d "$NO_PATH/conf/vhost" || mkdir "$NO_PATH/conf/vhost"
#	mkdir /var/www/
	test -d /var/www/google || mkdir -p /var/www/google
	cd /var/www/google
	wget -N --no-check-certificate https://raw.githubusercontent.com/Char1sma/Shell_Collections/master/ngx_google_deployment/index.html
	sed -i "s/g.doufu.ru/$NO_SEARCH/" /var/www/google/index.html
	sed -i "s/x.doufu.ru/$NO_SCHOLAR/" /var/www/google/index.html
#	SSL Key
	sslcert
#	start nginx
	"$NO_PATH/sbin/nginx"
	if [ $? -eq 0 ]; then
		echo "# Everything seems OK!"
		echo "# Go ahead to see your google!"
		echo "# !!!Do not modify nginx.conf!!!"
	else
		echo "# Installing errors!"
		echo "# Reinstall OR Contact me!"
	fi
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
	if [ "$NO_SYST" = "Debian" ]; then
		echo -n "To be sure your system is Debian/Ubuntu,please enter 'y/yes' to continue: "
	elif [ "$NO_SYST" = "Centos" ]; then
		echo -n "To be sure your system is Centos,please enter 'y/yes' to continue: "
	fi
	read -r key
	if [ "$key" = "yes" ]||[ "$key" = "y" ]; then
		read -p "Set your domain for google search: " search_domain
		read -p "Set your domain for google scholar: " scholar_domain
		if [ ! $search_domain ]||[ ! $scholar_domain ]||[ $search_domain = $scholar_domain ]; then
			echo "Two domains should not be null OR the same! Error happens!"
			exit 1
		else
			echo "your google search domain is $search_domain"
			echo "your google scholar domain is $scholar_domain"
			read -p "Press any key to continue ... or CTRL+C to exit" goodmood
		fi
	else
		exit 1
	fi
	cat >> "$HOME/nginx_onekey_config" << EOF
NO_SEARCH=$search_domain
NO_SCHOLAR=$scholar_domain
NO_SYST=$NO_SYST
NO_TEMP=/tmp/nginx_onekey
NO_CUST=no
NO_STREAM=no
NO_USER=www
NO_GROUP=www
NO_PATH=/etc/nginx
NO_CONF=/etc/nginx/conf/nginx.conf
NO_LOGP=/var/log/nginx
EOF
}
function update {
#2.Kill:80
	kill80
#2.Configure
	source "$HOME/nginx_onekey_config"
	read -p "Do you need to change your domain for google and schoolar?(y/N):" change
	if [ "$change" = "y" ] || [ "$change" = "Y" ]; then
		read -p "Set your domain for google search: " domain1
		read -p "Set your domain for google scholar: " domain2
		if [ ! $domain ]||[ ! $domain2 ]||[ $domain1 = $domain2 ]; then
			echo "Two domains should not be null OR the same! Error happens!"
			exit 1
		else
			echo "your google search domain is $search_domain"
			echo "your google scholar domain is $scholar_domain"
			read -p "Press any key to continue ... " goodmood
		fi
		rm "/var/www/ssls/$NO_SEARCH.*" -rf
		rm "/var/www/ssls/$NO_SCHOLAR.*" -rf
		cat >> "$HOME/nginx_onekey_config" << EOF
$NO_SEARCH=$domain1
$NO_SCHOLAR=$domain2
NO_SYST=$NO_SYST
NO_TEMP=$NO_TEMP
NO_CUST=no
NO_STREAM=no
NO_USER=$NO_USER
NO_GROUP=$NO_USER
NO_PATH=$NO_PATH
NO_CONF=$NO_CONF
NO_LOGP=$NO_LOGP
EOF
		install
		cd "$NO_PATH/conf/"
		mv -f nginx.conf nginx.conf.bak
		wget -N --no-check-certificate https://raw.githubusercontent.com/Char1sma/Shell_Collections/master/ngx_google_deployment/nginx.conf
		sed -i "s/g.doufu.ru/$NO_SEARCH/" nginx.conf
		sed -i "s/x.doufu.ru/$NO_SCHOLAR/" nginx.conf
		sslcrt;
	else
		$NO_PATH/sbin/nginx
		if [ $? -eq 0 ]; then
			echo "# Everything seems OK!"
			echo "# Go ahead to see your google!"
			echo "# !!!Do not modify nginx.conf!!!"
		else
			echo "#Installing errors!"
			echo "#Reinstall OR Contact me!"
		fi
	fi
}
function kill80 {
	yum update || apt-get update
	yum install lsof -y|| apt-get install lsof -y
	lsof -i :80|grep -v 'PID'|awk '{print $2}'|xargs kill -9
	if [ $? -eq 0 ]; then
        echo ":80 process has been killed!"
	else
		echo "no :80 process!"
    fi
}
function sslcert {
	source "$HOME/nginx_onekey_config"
	mkdir -p /var/www/ssls
	cd /var/www/ssls
	openssl req -nodes -newkey rsa:2048 -keyout $NO_SEARCH.key -out $NO_SEARCH.csr -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=$NO_SEARCH"
	openssl x509 -req -days 3650 -in $NO_SEARCH.csr -signkey $NO_SEARCH.key -out $NO_SEARCH.crt
	openssl req -nodes -newkey rsa:2048 -keyout $NO_SCHOLAR.key -out $NO_SCHOLAR.csr -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=$NO_SCHOLAR"
	openssl x509 -req -days 3650 -in $NO_SCHOLAR.csr -signkey $NO_SCHOLAR.key -out $NO_SCHOLAR.crt
}
function clean {
	source "$HOME/nginx_onekey_config"
	rm -rf "$NO_TEMP"
	rm -rf "$NO_PATH"
	rm -rf "$NO_LOGP"
	rm -f "$HOME/nginx_onekey_config"
	rm -rf /var/www/google
	rm "/var/www/ssls/$NO_SEARCH.*" -rf
	rm "/var/www/ssls/$NO_SCHOLAR.*" -rf
	echo "# All has been done!"
}
function uninstall {
	source "$HOME/nginx_onekey_config"
	read -p "Press any key to start uninstall or CTRL + C to exit..."
	"$NO_PATH/sbin/nginx -s stop"
	# restore /etc/rc.local
    if [[ -s /etc/rc.local_bak ]]; then
        rm -f /etc/rc.local
        mv /etc/rc.local_bak /etc/rc.local
    fi
	clean
	echo "# Ngx_google_deployment uninstall success!"
}
slogan
case $1 in
	h|H|help)
		echo "Usage: $0 [OPTION]"
		echo ""
		echo "Here are the options:"
		echo "install       install ngx_google_deployment"
		echo "uninstall     uninstall ngx_google_deployment"
		echo "update        update nginx.conf";;
	update)
		if [ -f "$HOME/nginx_onekey_config" ]; then
			update
		else
			echo "It seem that you don't have installed ngx_google_deployment"
			exit 1;
		fi;;
	install)
		install;;
	uninstall)
		uninstall
		;;
	*)
		echo "$0 : invalid option -- '$1'"
		echo "Try '$0 help' for more infomation."
		exit 0;;
esac