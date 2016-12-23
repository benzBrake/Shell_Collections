#!/usr/bin/env bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
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
CUR_DIR=$(pwd)
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
		for packages in unzip openssl-devel gcc swig python python-devel python-setuptools m2crypto autoconf libtool libevent automake make curl curl-devel zlib-devel perl perl-devel cpio expat-devel gettext-devel
		do
			echo -e "|\n|   Notice: Installing required package '$packages' via 'yum'"
			yum -y install $packages
		done
	fi
}
install() {
	cd "$CUR_DIR"
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
		cd "$CUR_DIR" && rm -rf libsodium*
	fi
	#Install shadowsocksR
	cd "$INSTALL_DIR"
	if ! wget --no-check-certificate -O manyuser.zip https://github.com/breakwa11/shadowsocks/archive/manyuser.zip; then
		echo "Failed to download ShadowsocksR file!"
		exit 1
	fi
	unzip manyuser.zip && rm manyuser.zip
	mv -f shadowsocks-manyuser/shadowsocks ${INSTALL_DIR}/${FOLDER}
	rm -rf shadowsocks-manyuser
	if [ -f "${INSTALL_DIR}/${FOLDER}/server.py" ]; then
		if [ -n "$(command -v apt-get)" ]; then
			if ! wget --no-check-certificate https://raw.githubusercontent.com/Char1sma/Shell_Collections/master/shadowsocks_installer/shadowsocksR-debian -O /etc/init.d/shadowsocks; then
				echo "Failed to download ShadowsocksR chkconfig file!"
				exit 1
			fi
			sed -i "s#/usr/local/shadowsocks-rss#${INSTALL_DIR}/${FOLDER}#g" /etc/init.d/shadowsocks
			chmod +x /etc/init.d/shadowsocks
			update-rc.d -f shadowsocks defaults
		elif [ -n "$(command -v yum)" ]; then 
			if ! wget --no-check-certificate https://raw.githubusercontent.com/Char1sma/Shell_Collections/master/shadowsocks_installer/shadowsocksR -O /etc/init.d/shadowsocks; then
				echo "Failed to download ShadowsocksR chkconfig file!"
				exit 1
			fi
			sed -i "s#/usr/local/shadowsocks-rss#${INSTALL_DIR}/${FOLDER}#g" /etc/init.d/shadowsocks
			chmod +x /etc/init.d/shadowsocks
			chkconfig --add shadowsocks
			chkconfig shadowsocks on
		fi 
		# Set up firewall rules
		echo "Set up firewall rules"
		if [ $OS_VERSION -eq 7 ] && [ -n "$(command -v yum)" ]; then
			systemctl status firewalld > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				firewall-cmd --permanent --zone=public --add-port=${PORT}/tcp
				firewall-cmd --permanent --zone=public --add-port=${PORT}/udp
				firewall-cmd --reload
			else
				systemctl start firewalld
				if [ $? -eq 0 ]; then
					firewall-cmd --permanent --zone=public --add-port=${PORT}/tcp
					firewall-cmd --permanent --zone=public --add-port=${PORT}/udp
					firewall-cmd --reload
				fi
			fi
		else
			test $(command -v iptables) && {
				iptables -L -n | grep -i ${PORT} > /dev/null 2>&1
				if test $? -ne 0 ; then
					iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${PORT} -j ACCEPT
					iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${PORT} -j ACCEPT
				fi
			}
		fi
		cat > /etc/shadowsocks_uninstall <<-EOF
INSTALL_DIR=${INSTALL_DIR}
FOLDER=${FOLDER}
EOF
		# Write Config
		cat > /etc/shadowsocks.json<<-EOF
{
	"server":"0.0.0.0",
	"server_ipv6":"::",
	"server_port":${PORT},
	"local_address":"127.0.0.1",
	"local_port":1080,
	"password":"${PASSWORD}",
	"timeout":120,
	"method":"${METHOD}",
	"protocol":"${PROTO}",
	"protocol_param":"",
	"obfs":"${OBFS}",
	"obfs_param":"${OBFS_PARAM}",
	"redirect":"",
	"dns_ipv6":false,
	"fast_open":false,
	"workers":1
}
EOF
		end
	fi
}
end() {
	/etc/init.d/shadowsocks start
	test $? -ne 0 && { echo -e "\033[41;37m [ERROR] \033[0m Shadowsocks install failed!";exit 1; }
	clear
	echo
	echo "Congratulations, ShadowsocksR install completed!"
	echo -e "Server IP: \033[41;37m $(get_ip) \033[0m"
	echo -e "Server Port: \033[41;37m ${PORT} \033[0m"
	echo -e "Password: \033[41;37m ${PASSWORD} \033[0m"
	echo -e "Local IP: \033[41;37m 127.0.0.1 \033[0m"
	echo -e "Local Port: \033[41;37m 1080 \033[0m"
	echo -e "Protocol: \033[41;37m ${PROTO} \033[0m"
	echo -e "obfs: \033[41;37m ${OBFS} \033[0m"
	echo -e "obfs_param: \033[41;37m ${OBFS_PARAM} \033[0m"
	echo -e "Encryption Method: \033[41;37m ${METHOD} \033[0m"
}
install_shadowsocks() {
	prepare
	install
	end
}
uninstall_shadowsocks(){
	source /etc/shadowsocks_uninstall
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
		rm -rf "${INSTALL_DIR}/${FOLDER}"
		rm -f /etc/shadowsocks_uninstall
		echo "ShadowsocksR uninstall success!"
	else
		echo
		echo "uninstall cancelled, nothing to do..."
		echo
	fi
}
help_info() {
	echo "Usage: $(basename $0) [OPTION[=PATTERN]]"
	echo "A ShadowsocksR Installer and Uninstaller."
	echo "Different OPTION has different PATTERN."
	echo "Example: $(basename $0) -i -p=443"
	echo ""
	echo "OPTIONs and PATTERNs"
	echo "  -i,-install			install ShadowsocksR"
	echo "  -u,-uninstall			uninstall ShadowsocksR"
	echo "  -p=NUM,--port=NUM		ShadowsocksR port"
	echo "  -k=STR,--password=STR		ShadowsocksR password"
	echo "  -m=STR,--method=STR		Encryption Method"
	echo "  -O=STR,--obfs=STR		OBFS Plugin"
	echo ""
	echo "Report bugs to github-char1sma@woai.ru"
	echo "Thanks to Teddysun <i@teddysun.com>"
}
action=$@
for i in "$@"
do
	case $i in
	-i=*|--install=*)
		if test -z "$FLAG" ; then
			FLAG=install
			DIRECTORY="${i#*=}"
		elif [ "$FLAG" == "uninstall" ]; then
			ERROR=yes
			HELP=yes
		fi
		shift
	;;
	-i|--install)
		if test -z "$FLAG" ; then
			FLAG=install
		elif [ "$FLAG" == "uninstall" ]; then
			ERROR=yes
			HELP=yes
		fi
		shift
	;;
	-p=*|--port=*)
		PORT="${i#*=}"
	;;
	-k=*|--password=*)
		PASSWORD="${i#*=}"
	;;
	-m=*|--method=*)
		METHOD="${i#*=}"
	;;
	-l=*|--protocol=*)
		PROTO="${i#*=}"
	;;
	
	-O=*|--obfs=*)
		OBFS="${i#*=}"
	;;
	-o=*|--obfs-param=*)
		OBFS_PARAM="${i#*=}"
	;;
	-u|--uninstall|uninstall)
		if test -z "$FLAG"  && test -z "$DIRECTORY" ; then
			FLAG=uninstall
		else
			ERROR=yes
			HELP=yes
		fi
		shift
	;;
	-h|--help)
		FLAG=
		HELP=yes
		shift
	;;
	*)
		# unknown option
		FLAG=
		ERROR=yes
		HELP=yes
	;;
	esac
done
test "$ERROR" == "yes" && echo -e "$(basename $0):Arguments error! [$action]\n============================="
if test -z $FLAG ; then
	test "$HELP" == "yes"  && help_info
elif test "$ERROR" != "yes" ; then
	#Check Root
	[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }
	if test "$FLAG" == "install"; then
		test -f /etc/shadowsocks_uninstall && { echo -e "\033[41;37m [ERROR] \033[0m It seem that you have installed shadowsocksR!";exit 1; }
		# Set ShadowsocksR install directory
		if test -z "$DIRECTORY"; then
			INSTALL_DIR=/usr/local
		else
			INSTALL_DIR=$(echo ${DIRECTORY} | sed 's#/$##')
		fi
		# FOLDER can not be changed!
		FOLDER=shadowsocks
		# Set ShadowsocksR config password
		test -z "$PASSWORD" && {
			echo "Please input password for ShadowsocksR:"
			read -p "(Default password: doufu.ru):" PASSWORD
			test -z "${PASSWORD}"  && PASSWORD="doufu.ru"
		}
		# Set ShadowsocksR config port
		test -z "$PORT" && {
			while true
			do
			echo -e "Please input port for ShadowsocksR [1-65535]:"
			read -p "(Default port: 8989):" PORT
			test -z "${PORT}" && PORT="8989"
			expr ${PORT} + 0 &>/dev/null
			if [ $? -eq 0 ]; then
				if [ ${PORT} -ge 1 ] && [ ${PORT} -le 65535 ]; then
					break
				else
					echo "Input error, please input correct number"
				fi
			else
				echo "Input error, please input correct number"
			fi
			done
		}
		test -z "${METHOD}" && METHOD="chacha20"
		test -z "${PROTO}" && PROTO="auth_sha1_compatible"
		test -z "${OBFS}" && OBFS="http_simple_compatible"
		test -z "${OBFS_PARAM}" && test $(echo ${OBFS} |grep -i 'http_simple') && OBFS_PARAM="bing.com,microsoft.com,live.com,outlook.com"
		prepare
		install
	elif test "$FLAG" == "uninstall" ; then
		uninstall_shadowsocks
	fi
fi
test -z "$action" && help_info