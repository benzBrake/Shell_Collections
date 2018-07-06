#!/usr/bin/env bash
#
# RyLLMP v1.01
# Mod From Rylig v1.02
# by Ryan
# Blog : http://blog.iplayloli.com
# 2018.07.03
#
CURLD=curl
APTD=apt-get
function ry_echo()
{
    echo $(tput setaf 4)$@$(tput sgr0)
}
function ry_echo_info()
{
    echo $(tput setaf 7)$@$(tput sgr0)
}
function ry_echo_fail()
{
    echo $(tput setaf 1)$@$(tput sgr0)
}
get_ip(){
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    [ ! -z ${IP} ] && echo ${IP} || echo
}
anykey()
{
       SAVEDSTTY=`stty -g`
       stty -echo
       stty raw
       dd if=/dev/tty bs=1 count=1 2> /dev/null
       stty -raw
       stty echo
       stty $SAVEDSTTY
}
clear
echo ""
echo "    -----------------------------------------"
echo "    |       Welcome to use RyLLMP v1.01     |"
echo "    |  LLMP Linux + Lighttpd + MySQL + PHP  |"
echo "    -----------------------------------------"
echo ""
ry_echo_info "1. You must install lighttod."
# PHP Options
read -p "2. Do you want to install php? [Y/n] " aphp
case $aphp in
	Y|y)
		ryphp="y"
		ry_echo "PHP5 will be installed."
		;;
	N|n)
		ryphp="n"
		ry_echo "PHP5 will not be installed."
		;;
	*)
		ryphp="y"
		ry_echo "PHP5 will be installed."
		;;
esac


# MySQL Options
read -p "3. Do you want to install MySQL Server? [Y/n] " amysql
case $amysql in
	Y|y)
		rymysql="y"
		ry_echo "MySQL will be installed."
		;;
	N|n)
		rymysql="n"
		ry_echo "MySQL will not be installed."
		;;
	*)
		rymysql="y"
		ry_echo "MySQL will be installed."
		;;
esac

# SQLite Options
read -p "4. Do you want to install SQLite? [Y/n] " asqlite
case $asqlite in
	Y|y)
		rysqlite="y"
		ry_echo "SQLite will be installed."
		;;
	N|n)
		rysqlite="n"
		ry_echo "SQLite will not be installed."
		;;
	*)
		rysqlite="y"
		ry_echo "SQLite will be installed."
		;;
esac

# Confirm to install
ry_echo_info "Press any key to continue or Ctrl+C to exit."
char=`anykey`

# Start install
ry_echo "### Start installing lighttpd ###"
${APTD} purge -y apache*
${APTD} -y update && ${APTD} -y upgrade
${APTD} install -y lighttpd unzip

if [ "$rymysql" == "y" ]
then
	ry_echo "### Start installing MySQL ###"
	${APTD} install -y mysql-server php5-mysql
	ry_echo "### Preparing phpMyAdmin ###"
	cat >> /etc/lighttpd/conf-available/10-phpMyAdmin.conf <<EOF
\$SERVER["socket"] == "0.0.0.0:9001" {
server.document-root = "/var/llmp/phpMyAdmin"
}
EOF
	ln -s /etc/lighttpd/conf-available/10-phpMyAdmin.conf /etc/lighttpd/conf-enabled/
	mkdir -p /var/llmp
	cd /var/llmp
	#PHPMADL=`${CURLD} https://www.phpmyadmin.net/downloads/ | grep "languages.tar.gz\"" | head -n 1 | sed 's#.*href="##;s#".*##'`
	# Old Version PMA
	if [ "$rymysql" == "y"]
	then
		PHPMADL=https://files.phpmyadmin.net/phpMyAdmin/4.0.10.20/phpMyAdmin-4.0.10.20-all-languages.tar.gz
		${CURLD} -o phpMyAdmin.tgz ${PHPMADL}
		if [ $? -eq 127 ]; then
			# curl commant not found
			${APTD} -y install curl
			${CURLD} -o phpMyAdmin.tgz ${PHPMADL}
		fi
		tar zxvf phpMyAdmin.tgz
		rm -f /var/llmp/phpMyAdmin.tgz
		mv phpMyAdmin-4.0.10.20-all-languages phpMyAdmin
	fi
fi

# Install SQLite
if [ "$rysqlite" == "y" ]
then
	ry_echo "###Start installing SQLite ###"
	${APTD} install -y sqlite
fi

# Install PHP5
if [ "$ryphp" == "y" ]
then
	ry_echo "### Start installing PHP ###"
	${APTD} install -y php5-cgi php5-common php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-snmp php5-sqlite php5-xmlrpc php5-xsl
	lighty-enable-mod fastcgi
	lighty-enable-mod fastcgi-php
	service lighttpd restart
fi

# Change Owner
chown -R www-data:www-data /var/log/lighttpd /var/www

# Add default index.php
cd `grep server.document-root /etc/lighttpd/lighttpd.conf | awk -F\" '{print $2}'`
${CURLD} -O https://github.com/benzBrake/Shell_Collections/raw/master/RyLLMP/index.php
echo '' >> /etc/lighttpd/lighttpd.conf
echo 'server.tag="Lighttpd ( For <a href=http://blog.iplayloli.com/llmp.html target=_blank>RyLLMP</a> )"' >> /etc/lighttpd/lighttpd.conf
service lighttpd restart

clear
ry_echo ""
ry_echo "    -----------------------------------------"
ry_echo "    |------Welcome to use RyLLMP v1.01------|"
ry_echo "    |--------Congratulations to you !!------|"
ry_echo "    |--LLMP have installed successfully @~@-|"
ry_echo "    -----------------------------------------"
ry_echo_info "     You can upload your website to /var/www "
ry_echo_info "        and access it via http://"`get_ip`"/    "
ry_echo_info "      phpMyAdmin :  http://"`get_ip`":9001 "
ry_echo ""
service lighttpd status