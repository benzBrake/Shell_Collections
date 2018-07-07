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
#               ngx_google_deployment_mod_C Install Shell
# Version :         0.2
# Script author :   benzBrake<github-benzBrake@woai.ru>
# Blog :            http://blog.iplayloli.com
# System Required : Centos/Debian/Ubuntu
# Project url :     https://github.com/Shell_Collections/ngx_google_deployment
# Thanks To :       arnofeng<http://github.com/arnofeng>
#========================================================================
"
}
function install {
#	读取配置
	if [ -f "$HOME/nginx_onekey_config" ]; then
		source "$HOME/nginx_onekey_config"
	else
		configure
	fi

#	清除80端口占用
	kill80

#	下载 Nginx 模块
	mkdir -p ${NO_MODULES} && cd ${NO_MODULES}
	wget -N --no-check-certificate https://github.com/benzBrake/Shell_Collections/raw/master/Nginx_OneKey/modules/ngx_http_substitutions_filter_module.tgz
	tar -xzvf ngx_http_substitutions_filter_module.tgz
	rm -rf ngx_http_substitutions_filter_module.tgz
	cd ${NO_TEMP}

#	安装 Nginx
	bash -c "$(wget --no-check-certificate https://raw.githubusercontent.com/benzBrake/Shell_Collections/master/Nginx_OneKey/onekey.sh -O -)" -c "install"
#	停止 Nginx
	service nginx stop

#	下载 Nginx 配置文件
	source "$HOME/nginx_onekey_config"
	cd "$NO_PATH"
	test -d "$NO_PATH/conf" || mkdir "$NO_PATH/conf"
	cd "$NO_PATH/conf"
	if [ -f "./nginx.conf" ]; then
		mv nginx.conf nginx.conf.bak
	fi
	wget -N --no-check-certificate https://raw.githubusercontent.com/benzBrake/Shell_Collections/master/ngx_google_deployment/nginx.conf
	sed -i "s/g.doufu.ru/$NO_SEARCH/" nginx.conf
	sed -i "s/x.doufu.ru/$NO_SCHOLAR/" nginx.conf
	test -d "$NO_PATH/conf/vhost" || mkdir "$NO_PATH/conf/vhost"

#	创建 /var/www/
	test -d /var/www/google || mkdir -p /var/www/google
	cd /var/www/google
	wget -N --no-check-certificate https://raw.githubusercontent.com/benzBrake/Shell_Collections/master/ngx_google_deployment/index.html
	sed -i "s/g.doufu.ru/$NO_SEARCH/" /var/www/google/index.html
	sed -i "s/x.doufu.ru/$NO_SCHOLAR/" /var/www/google/index.html

#	自签 SSL 证书
	sslcert

#	启动 Nginx
	service nginx start
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
	if [ -n "$(command -v yum)" ]; then
		NO_SYST=Centos
	elif [ -n "$(command -v apt-get)" ]; then
		NO_SYST=Debian
	else
		exit 1
	fi
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

#   Kill:80
	kill80

#   Configure
	source "$HOME/nginx_onekey_config"
	read -p "Do you need to change your domain for google and schoolar?(y/N):" change
	if [ "$change" = "y" ] || [ "$change" = "Y" ]; then
		read -p "Set your domain for google search: " domain1
		read -p "Set your domain for google scholar: " domain2
		if [ ! $domain1 ]||[ ! $domain2 ]||[ $domain1 = $domain2 ]; then
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
	sslcert
	service nginx restart
	else
		exit 1
	fi
}
function kill80 {
	if [ -n "$(command -v yum)" ]; then
		yum update -y
		yum install lsof -y
	elif [ -n "$(command -v systemctl)" ]; then
		apt-get update -y
		apt-get install lsof -y
	fi
	lsof -i :80|grep -v 'PID'|awk '{print $2}'|xargs kill -9
	if [ $? -eq 0 ]; then
		echo ":80 process has been killed!"
	else
		echo "no :80 process!"
	fi
}
function sslcert {
#	自签SSL证书
	source "$HOME/nginx_onekey_config"
	rm -rf /var/www/ssls
	mkdir -p /var/www/ssls
	cd /var/www/ssls
	wget https://raw.githubusercontent.com/benzBrake/Shell_Collections/master/ngx_google_deployment/openssl.cnf -O openssl.cnf
	sed -i "s/g.doufu.ru/$NO_SEARCH/" openssl.cnf
	sed -i "s/x.doufu.ru/$NO_SCHOLAR/" openssl.cnf
	openssl genrsa -out ngx_google_deployment.key 2048
	openssl req -new -key ngx_google_deployment.key -out ngx_google_deployment.csr -config openssl.cnf
	openssl x509 -req -days 3650 -in ngx_google_deployment.csr -signkey ngx_google_deployment.key -out ngx_google_deployment.crt
}
function clean {
	source "$HOME/nginx_onekey_config"
	rm -rf "$NO_TEMP"
	rm -rf "$NO_PATH"
	rm -rf "$NO_LOGP"
	rm -rf "$NO_MODULES"
	rm -f "$HOME/nginx_onekey_config"
	rm -rf /var/www/google
	rm "/var/www/ssls" -rf
	echo "# All has been done!"
}
function uninstall_Service {
#   Install nginx auto startup service.
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
	source "$HOME/nginx_onekey_config"
	read -p "Press any key to start uninstall or CTRL + C to exit..."
	uninstall_Service
	clean
	echo "# Ngx_google_deployment uninstall successful!"
}
slogan
case $1 in
	h|H|help)
		echo "Usage: $0 [OPTION]"
		echo ""
		echo "Here are the options:"
		echo "install	   install ngx_google_deployment"
		echo "uninstall	 uninstall ngx_google_deployment"
		echo "update		update nginx.conf"
		;;
	update)
		if [ -f "$HOME/nginx_onekey_config" ]; then
			update
		else
			echo "It seem that you don't have installed ngx_google_deployment"
			exit 1
		fi
		;;
	install)
		install
		;;
	uninstall)
		uninstall
		;;
	*)
		echo "$0 : invalid option -- '$1'"
		echo "Try '$0 help' for more infomation."
		exit 0
		;;
esac
