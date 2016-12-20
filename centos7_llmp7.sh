#!/bin/bash
#Question
DB_Root_Password="root"
echo "Please setup root password of MySQL.(Default password: root)"
read -p "Please enter: " DB_Root_Password
if [ "${DB_Root_Password}" = "" ]; then
	DB_Root_Password="root"
fi
echo "Setting timezone..."
rm -rf /etc/localtime
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
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
cp /etc/yum.conf /etc/yum.conf.llxp
sed -i 's:exclude=.*:exclude=:g' /etc/yum.conf
echo "[+] Yum installing dependent packages..."
for packages in make cmake gcc gcc-c++ gcc-g77 flex bison file libtool libtool-libs autoconf kernel-devel patch wget libjpeg libjpeg-devel libpng libpng-devel libpng10 libpng10-devel gd gd-devel libxml2 libxml2-devel zlib zlib-devel glib2 glib2-devel unzip tar bzip2 bzip2-devel libevent libevent-devel ncurses ncurses-devel curl curl-devel libcurl libcurl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel vim-minimal gettext gettext-devel ncurses-devel gmp-devel pspell-devel unzip libcap diffutils ca-certificates net-tools libc-client-devel psmisc libXpm-devel git-core c-ares-devel libicu-devel libxslt libxslt-devel;
do yum -y install $packages; done
mv -f /etc/yum.conf.lnmp /etc/yum.conf
yum -y install mariadb mariadb-server
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum -y install lighttpd
yum -y install php php-fpm php-cgi php-mysql php-sqlite
yum -y install yum-plugin-replace
yum -y replace php-common --replace-with=php70w-common
sed -i 's/;cgi\.fix_pathinfo=1/cgi.fix_pathinfo=1/' /etc/php.ini
service lighttpd start
service php-fpm restart
service mariadb start
mysql_secure_installation <<EOF

y
${DB_Root_Password}
${DB_Root_Password}
y
y
y
y
EOF
