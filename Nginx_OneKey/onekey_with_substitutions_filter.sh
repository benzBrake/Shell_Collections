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
	rm "$NO_MODULES" -rf
	rm "$HOME/nginx_onekey_config" -f
	echo "# All has been done!"
}
function install {
	write_Conf
	mkdir -p ${NO_MODULES} && cd ${NO_MODULES}
	wget --no-check-certificate https://github.com/benzBrake/Shell_Collections/raw/master/Nginx_OneKey/modules/ngx_http_substitutions_filter_module.tgz
	tar zxvf ngx_http_substitutions_filter_module.tgz
	rm -rf ngx_http_substitutions_filter_module.tgz
	bash -c "$(wget --no-check-certificate https://raw.githubusercontent.com/benzBrake/Shell_Collections/master/Nginx_OneKey/onekey.sh -O -)" -c "install"
}
case "$1" in
install)
	install;;
uninstall)
	uninstall;;
clean)
	clean;;
*)
	echo "unrecognized option:"
	echo "-------------------------------------"
	echo "Usage: $0 [option]"
	echo "$0 install    install Nginx Onekey"
	echo "$0 uninstall  uninstall Nginx Onekey"
	exit 1
	;;
esac
