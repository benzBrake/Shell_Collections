#!/usr/bin/env bash
test -z "$WORKING_DIR" && WORKING_DIR=$( pwd )
OS_VERSION=$(grep -oEh "[0-9]+" /etc/*-release | head -n 1) || {
		cat >&2 <<-'EOF'
		Fail to detect os version, please feed back to author!
		EOF
		exit 1
	}
INSTALL_ROOT=/usr/local/cloud-torrent
help_info() {
	echo "Usage: $(basename $0) [OPTION[=PATTERN]]"
	echo "Cloud Torrent installer"
	echo "Different OPTION has different PATTERN."
	echo "Example: $(basename $0) -i -p=8000"
	echo ""
	echo "OPTIONs and PATTERNs"
	echo "  -i,--install		install cloud torrent"
	echo "  -u,--uninstall	uninstall cloud torrent"
	echo "  -p,--port		listen port for cloud torrent"
	echo ""
	echo "Report bugs to benzBrake<github-benzBrake@woai.ru>"
}
pass() {
    echo >/dev/null
}
get_ip(){
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    [ ! -z ${IP} ] && echo ${IP} || echo
}
action="$@"
for i in "$@"
do
	case "$i" in
	-i|--install)
		if test -z ${FLAG}; then
			FLAG=install
		else
			ERROR=yes
		fi
		shift
	;;
    -u|--uninstall)
		if test -z ${FLAG}; then
			FLAG=uninstall
		else
			ERROR=yes
		fi
		shift
    ;;
	-p=*|--port=*)
		CT_PORT="${i#*=}"
		shift
	;;
	-h|[hH]|[hH][eE][lL][pP])
		help_info
		shift
	;;
	*)
		ERROR=yes
	;;
	esac
done
test -z "$action" && {
	help_info
	exit 0
}
if test -z "$ERROR"; then
	if test "$FLAG" == "install"; then
		test -d "${UNINSTALL_ROOT}" && {
			test -e "${UNINSTALL_ROOT}/cloud-torrent" && {
				echo "[Error] It seem that you have install cloud-torrent"
				exit 1
			}
		}
		PROCESSES=$( ps aux | grep -v grep | grep 'cloud-torrent' )
		if test -z "$PROCESSES"; then
			test -z "$CT_PORT" && {
				while :; do echo
					echo "Please input listen port for Cloud Torrent [1-65535]"
					read -p "(Default: 1024):" CT_PORT
					test -z "$CT_PORT" && CT_PORT="1024"
					USING=$( netstat -ntlp | grep ":{$CT_PORT}" )
					expr ${CT_PORT} + 0 &>/dev/null
					test "$?" -eq 0 && {
						if test -z "$USING" ; then
							break
						else
							echo -e "\033[41;37m [ERROR] \033[0m Port ${CT_PORT} is used."
						fi
					}
				done
			}
			read -p "Please input username(Default: benzBrake):" CT_USER
			test -z "$CT_USER" && CT_USER="benzBrake"
			read -p "Please input password(Default: doufu.ru):" CT_PASS
			test -z "$CT_PASS" && CT_PASS="doufu.ru"
			#confirm
			pass
			if ! wget --no-check-certificate https://raw.githubusercontent.com/benzBrake/Shell_Collections/master/CloudTorrent/prepare.sh; then
				echo "Failed to download prepare scripts!"
				exit 1
			fi
			source prepare.sh
			prepare
			rm -rf prepare.sh
			! test -d "${INSTALL_ROOT}" && mkdir -p "${INSTALL_ROOT}"
			cd "${INSTALL_ROOT}"
			CT_VER=$( curl -s "https://github.com/jpillora/cloud-torrent/releases/latest" | perl -e 'while($_=<>){ /\/tag\/(.*)\">redirected/; print $1;}' )
			SYS_BIT=$( getconf WORD_BIT )
			if test "${SYS_BIT}" == "64" ; then
				wget -N -O cloud-torrent.gz "https://github.com/jpillora/cloud-torrent/releases/download/${CT_VER}/cloud-torrent_linux_amd64.gz"
			elif test "${SYS_BIT}" == "32" ; then
				wget -N -O cloud-torrent.gz "https://github.com/jpillora/cloud-torrent/releases/download/${CT_VER}/cloud-torrent_linux_386.gz"
			else
				echo -e "\033[41;37m [ERROR] \033[0m Do not support ${SYS_BIT} !"
				exit 1
			fi
			if test ! -e "cloud-torrent.gz" ; then
				echo -e "\033[41;37m [ERROR] \033[0m Download Cloud Torrent failed !"
				exit 1
			fi
			gzip -d cloud-torrent.gz
			if test ! -e ${INSTALL_ROOT}"/cloud-torrent" ; then
				echo -e "\033[41;37m [ERROR] \033[0m Cloud Torrent is not installed !"
				exit 1
			fi
			chmod +x cloud-torrent
			if [ -n "$(command -v apt-get)" ]; then
				if ! wget --no-check-certificate https://raw.githubusercontent.com/benzBrake/Shell_Collections/master/CloudTorrent/cloud-torrent-debian -O /etc/init.d/cloud-torrent; then
					echo "Failed to download cloud-torrent chkconfig file!"
					exit 1
				fi
				chmod +x /etc/init.d/cloud-torrent
				update-rc.d -f cloud-torrent defaults
			elif [ -n "$(command -v yum)" ]; then
				if ! wget --no-check-certificate https://raw.githubusercontent.com/benzBrake/Shell_Collections/master/CloudTorrent/cloud-torrent -O /etc/init.d/cloud-torrent; then
					echo "Failed to download cloud-torrent chkconfig file!"
					exit 1
				fi
				chmod +x /etc/init.d/cloud-torrent
				chkconfig --add cloud-torrent
				chkconfig cloud-torrent on
			fi
			test -e /usr/local/cloud-torrent/cloud-torrent.conf && rm -f /usr/local/cloud-torrent/cloud-torrent.conf
			cat >> /usr/local/cloud-torrent/cloud-torrent.conf <<-EOF
			CT_USER=$CT_USER
			CT_PASS=$CT_PASS
			CT_PORT=$CT_PORT
			EOF
			/etc/init.d/cloud-torrent start
			sleep 2s
			PID=$( ps -ef | grep cloud-torrent | grep -v grep | awk '{print $2}' )
			if [ -z $PID ]; then
				echo -e "\033[41;37m [ERROR] \033[0m Cloud Torrent start failed! exit."
				exit 1
			else
				CUR_IP=$(get_ip)
				if test  -z "$CUR_IP" ; then
					CUR_IP="Your IP"
				fi
				echo
				echo "Cloud torrent start successful !"
				echo -e "Cloud Torrent web ui ： \033[41;37m http://${CUR_IP}:${CT_PORT} \033[0m "
				echo
			fi
		else
			echo "[Error] It seem that you have install cloud-torrent"
			exit 1
		fi
	elif test "$FLAG" == "uninstall"; then
		PID=$( ps -ef | grep cloud-torrent | grep -v grep | awk '{print $2}' )
		! test -z "$PID" && {
			kill -9 "$PID"
		}
		rm -f /etc/init.d/cloud-torrent
		rm -rf "${INSTALL_ROOT}"
		echo "[INFO] Uninstall Cloud Torrent successful!"
		exit 0
	else
		help_info
		exit 0
	fi
fi