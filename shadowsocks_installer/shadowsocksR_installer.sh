#!/usr/bin/env bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
INSTALL_DIR=/usr/local/
INSTALL_DIR=$(echo ${INSTALL_DIR} | sed 's#/$##')
OS_VERSION=$(grep -oEh "[0-9]+" /etc/*-release | head -n 1) || {
		cat >&2 <<-'EOF'
		Fail to detect os version, please feed back to author!
		EOF
		exit 1
	}
get_ip(){
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    [ ! -z ${IP} ] && echo ${IP} || echo
}
#Current folder
cur_dir=$(pwd)
#Check Root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }
question() {
	# Set ShadowsocksR config password
	echo "Please input password for ShadowsocksR:"
	read -p "(Default password: doufu.ru):" shadowsockspwd
	[ -z "${shadowsockspwd}" ] && shadowsockspwd="doufu.ru"
	# Set ShadowsocksR config port
	while true
	do
	echo -e "Please input port for ShadowsocksR [1-65535]:"
	read -p "(Default port: 8989):" shadowsocksport
	[ -z "${shadowsocksport}" ] && shadowsocksport="8989"
	expr ${shadowsocksport} + 0 &>/dev/null
	if [ $? -eq 0 ]; then
		if [ ${shadowsocksport} -ge 1 ] && [ ${shadowsocksport} -le 65535 ]; then
			echo "port = ${shadowsocksport}"
			break
		else
			echo "Input error, please input correct number"
		fi
	else
		echo "Input error, please input correct number"
	fi
	done
}
prepare() {
	rm -rf /etc/localtime
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	#Disable SELINUX
	if [ -s /etc/selinux/config ]; then
		sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
	fi
	if grep -Eqi '^127.0.0.1[[:space:]]*localhost' /etc/hosts; then
		echo "Hosts: ok."
	else
		echo "127.0.0.1 localhost.localdomain localhost" >> /etc/hosts
	fi
	ping -c1 doufu.ru
	if [ $? -eq 0 ] ; then
		echo "DNS...ok"
	else
		echo "DNS...fail"
		echo -e "nameserver 208.67.220.220\nnameserver 1.2.4.8" > /etc/resolv.conf
	fi
	#install dependence
	if [ -n "$(command -v apt-get)" ]; then
		apt-get -y update
		for packages in python python-dev python-pip python-m2crypto curl wget unzip gcc swig automake make perl cpio build-essential
		do
			if [ ${OS_VERSION} -eq 6 ]; then
				echo 'Acquire::Check-Valid-Until "false";' >/etc/apt/apt.conf.d/90ignore-release-date
				echo "deb http://archive.debian.org/debian-archive/debian squeeze main" > /etc/apt/sources.list
				echo "deb http://archive.debian.org/debian-archive/debian squeeze-proposed-updates main" >> /etc/apt/sources.list
				echo "deb http://security.debian.org squeeze/updates main" >> /etc/apt/sources.list
				echo "deb http://archive.debian.org/debian-archive/debian squeeze-lts main contrib non-free" >> /etc/apt/sources.list
				apt-get -y install debian-archive-keyring
			fi
			echo -e "|\n|   Notice: Installing required package '$packages' via 'apt-get'"
			apt-get -y install $packages
		done
	elif [ -n "$(command -v yum)" ]; then 
		for packages in unzip openssl-devel gcc swig python python-devel python-setuptools autoconf libtool libevent automake make curl curl-devel zlib-devel perl perl-devel cpio expat-devel gettext-devel
		do
			echo -e "|\n|   Notice: Installing required package '$packages' via 'yum'"
			yum -y install $packages
		done
	fi
}
install() {
	cd "$cur_dir"
	whereis libsodium.so 2>&1 | grep -i 'libsodium.so' >/dev/null
	if [ $? -ne 0 ]; then
		#Intall libsodium
		wget --no-check-certificate -O libsodium-1.0.10.tar.gz https://github.com/jedisct1/libsodium/releases/download/1.0.10/libsodium-1.0.10.tar.gz
		tar -xf libsodium-1.0.10.tar.gz && cd libsodium-1.0.10
		./configure && make && make install
		if [ $? -ne 0 ]; then
			echo "libsodium install failed!"
			exit 1
		fi
		echo "/usr/local/lib" > /etc/ld.so.conf.d/local.conf && ldconfig
		cd "$cur_dir" && rm -rf libsodium*
	fi
	#Install shadowsocksR
	cd "$INSTALL_DIR"
	if ! wget --no-check-certificate -O manyuser.zip https://github.com/breakwa11/shadowsocks/archive/manyuser.zip; then
		echo "Failed to download ShadowsocksR file!"
		exit 1
	fi
	unzip manyuser.zip && rm manyuser.zip
	mv -f shadowsocks-manyuser/shadowsocks ${INSTALL_DIR}/shadowsocks-rss
	rm -rf shadowsocks-manyuser
	if [ -f "${INSTALL_DIR}/shadowsocks-rss/server.py" ]; then
		if [ -n "$(command -v apt-get)" ]; then
			if ! wget --no-check-certificate https://raw.githubusercontent.com/Char1sma/Shell_Collections/master/shadowsocks_installer/shadowsocksR-debian -O /etc/init.d/shadowsocks; then
				echo "Failed to download ShadowsocksR chkconfig file!"
				exit 1
			fi
			sed -i "s#/usr/local#${INSTALL_DIR}#g" /etc/init.d/shadowsocks
			chmod +x /etc/init.d/shadowsocks
			chkconfig --add shadowsocks
			chkconfig shadowsocks on
		elif [ -n "$(command -v yum)" ]; then 
			if ! wget --no-check-certificate https://raw.githubusercontent.com/Char1sma/Shell_Collections/master/shadowsocks_installer/shadowsocksR -O /etc/init.d/shadowsocks; then
				echo "Failed to download ShadowsocksR chkconfig file!"
				exit 1
			fi
			sed -i "s#/usr/local#${INSTALL_DIR}#g" /etc/init.d/shadowsocks
			chmod +x /etc/init.d/shadowsocks
			update-rc.d -f shadowsocks defaults
		fi 
		# Set up firewall rules
		echo "Set up firewall rules"
		if [ OS_VERSION -eq 7 ]; then
			systemctl status firewalld > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				firewall-cmd --permanent --zone=public --add-port=${shadowsocksport}/tcp
				firewall-cmd --permanent --zone=public --add-port=${shadowsocksport}/udp
				firewall-cmd --reload
			else
				systemctl start firewalld
				if [ $? -eq 0 ]; then
					firewall-cmd --permanent --zone=public --add-port=${shadowsocksport}/tcp
					firewall-cmd --permanent --zone=public --add-port=${shadowsocksport}/udp
					firewall-cmd --reload
				fi
			fi
		fi
		/etc/init.d/iptables status > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			iptables -L -n | grep -i ${shadowsocksport} > /dev/null 2>&1
			iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${shadowsocksport} -j ACCEPT
			iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${shadowsocksport} -j ACCEPT
		fi
		# Write Config
		cat > /etc/shadowsocks.json<<-EOF
{
	"server":"0.0.0.0",
	"server_ipv6":"::",
	"server_port":${shadowsocksport},
	"local_address":"127.0.0.1",
	"local_port":1080,
	"password":"${shadowsockspwd}",
	"timeout":120,
	"method":"aes-256-cfb",
	"protocol":"origin",
	"protocol_param":"",
	"obfs":"plain",
	"obfs_param":"",
	"redirect":"",
	"dns_ipv6":false,
	"fast_open":false,
	"workers":1
}
EOF
		/etc/init.d/shadowsocks start
	fi
}
end() {
	#clean up
	
	clear
	echo
	echo "Congratulations, ShadowsocksR install completed!"
	echo -e "Server IP: \033[41;37m $(get_ip) \033[0m"
	echo -e "Server Port: \033[41;37m ${shadowsocksport} \033[0m"
	echo -e "Password: \033[41;37m ${shadowsockspwd} \033[0m"
	echo -e "Local IP: \033[41;37m 127.0.0.1 \033[0m"
	echo -e "Local Port: \033[41;37m 1080 \033[0m"
	echo -e "Protocol: \033[41;37m origin \033[0m"
	echo -e "obfs: \033[41;37m plain \033[0m"
	echo -e "Encryption Method: \033[41;37m aes-256-cfb \033[0m"
}
install_shadowsocks() {
	if [ -f "${INSTALL_DIR}/shadowsocks-rss/server.py" ]; then
		echo "it seem that you have installed shadowsocksR"
		exit 1
	fi
	question
	prepare
	install
	end
}
uninstall_shadowsocks(){
	printf "Are you sure uninstall ShadowsocksR? (y/n)"
	printf "\n"
	read -p "(Default: n):" answer
	[ -z ${answer} ] && answer="n"
	if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
		/etc/init.d/shadowsocks status > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			/etc/init.d/shadowsocks stop
		fi
		[ $(command -v apt-get) ] && update-rc.d -f shadowsocks remove
		[ $(command -v yum) ] && chkconfig --del shadowsocks
		rm -f /etc/shadowsocks.json
		rm -f /etc/init.d/shadowsocks
		rm -f /var/log/shadowsocks.log
		rm -rf "${INSTALL_DIR}/shadowsocks-rss"
		echo "ShadowsocksR uninstall success!"
	else
		echo
		echo "uninstall cancelled, nothing to do..."
		echo
	fi
}
action=$1
[ -z $1 ] && action=install
case "$action" in
	install|uninstall)
	${action}_shadowsocks
	;;
	*)
	echo "Arguments error! [${action}]"
	echo "Usage: $(basename $0) {install|uninstall}"
	;;
esac