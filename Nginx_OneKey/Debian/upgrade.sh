#!/bin/bash
# Nginx Upgrade Shell
# Tested with Debian 7 32/64bit
# Script author <github-charisma@32mb.cn>
# Blog : http://blog.iplayloli.com
#1.Load Config
source ~/nginx_onekey_config
test -d "$install_temp" || mkdir -p "$install_temp"
cd "$install_temp"
#2.Prepare and configure
apt-get update || apt-get update
apt-get install -y git gcc g++ make automake
if [ $? -eq 0 ]; then
	echo "git gcc g++ make automake installed"
else
	apt-get install -y git gcc g++ make automake
fi
#2.1.add user and group
/usr/sbin/groupadd -f $n_group
/usr/sbin/useradd -g $n_group $n_user
#2.2 Download Nginx
wget http://nginx.org/download/nginx-$nginx_ver.tar.gz
tar -xzvf nginx-$nginx_ver.tar.gz
if [ ! $? -eq 0 ]; then
	wget http://nginx.org/download/nginx-1.9.5.tar.gz
	tar -xzvf nginx-1.9.5.tar.gz
fi
#2.3 Download subs_filter
git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module
#2.4 Other preparation
case $complie_poz in
	yes)
#		Download and unpack PCRE
		wget $pcre_mirror/pcre-$pre_ver.tar.gz
		tar -xzvf pcre-$pcre_ver.tar.gz
#		Download and unpack OpenSSL
		wget $ossl_mirror/openssl-$ossl_ver.tar.gz
		tar -xzvf openssl-$ossl_ver.tar.gz
#		Download and unpack zLib
		wget $zlib_mirror/zlib-$zlib_ver.tar.gz
		tar -xzvf zlib-$zlib_ver.tar.gz
		cd nginx-$nginx_ver
		./configure --prefix=$install_path --conf-path=$conf_path --with-pcre=$install_temp/pcre-$pcre_ver --user=$n_user --group=$n_group --error-log-path=$log_path/error.log --http-log-path=$log_path/access.log --pid-path=/var/run/nginx/nginx.pid --lock-path=/var/lock/nginx.lock --with-ipv6 --with-http_ssl_module --with-openssl=$install_temp/openssl-$ossl_ver --with-http_stub_status_module --with-http_gzip_static_module --with-zlib=$install_temp/zlib-$zlib_ver --add-module=$install_temp/ngx_http_substitutions_filter_module
		;;
	*)
#		install pcre
		apt-get install -y libpcre3 libpcre3-dev
		if [ $? -eq 0 ]; then
			echo "libpcre3 libpcre3-dev installed"
		else
			apt-get install -y libpcre3 libpcre3-dev
		fi
#		install openssl zlib
		apt-get install -y zlib1g zlib1g-dev openssl libssl-dev
		if [ $? -eq 0 ]; then
			echo "zlib1g zlib1g-dev openssl libssl-dev installed"
		else
			apt-get install -y zlib1g zlib1g-dev openssl libssl-dev
		fi
		cd "nginx-$nginx_ver"
		./configure --prefix=$install_path --conf-path=$conf_path --user=$n_user --group=$n_group --error-log-path=$log_path/error.log --http-log-path=$log_path/access.log --pid-path=/var/run/nginx/nginx.pid --lock-path=/var/lock/nginx.lock --with-pcre-jit --with-ipv6 --with-http_ssl_module --with-http_stub_status_module --with-http_gzip_static_module --add-module=$install_temp/ngx_http_substitutions_filter_module
		;;
esac
#3.Installation
make
if [ ! $? -eq 0 ]; then
	echo "Compile nginx failed.Exit now!"
	rm -rf "$install_temp"
	exit 0
fi
make install
if [ ! $? -eq 0 ]; then
	echo "Nginx installed failed.Exit now!"
	rm -rf "$install_temp"
	exit 0
fi
echo "nginx sbin:$install_path/sbin/nginx"
#5.Make dir and clean
mkdir -p "$log_path"
rm -rf "$install_temp"
