prepare() {
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
	if test $? -eq 0 ; then
		echo "DNS...ok"
	else
		Echo_Red "DNS...fail"
		echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf
	fi
	if test -n "$(command -v apt-get)" ; then
		if test "${OS_VERSION}" -eq "6" ; then
			mv -f /etc/apt/sources.list /etc/apt/sources.list.ct
			echo 'Acquire::Check-Valid-Until "false";' >/etc/apt/apt.conf.d/90ignore-release-date
			{
				echo "deb http://archive.debian.org/debian-archive/debian squeeze main"
				echo "deb http://archive.debian.org/debian-archive/debian squeeze-proposed-updates main"
				echo "deb http://security.debian.org squeeze/updates main"
				echo "deb http://archive.debian.org/debian-archive/debian squeeze-lts main contrib non-free"
			} >> /etc/apt/sources.list
			apt-get -y install debian-archive-keyring
		fi
		grep 'deb\s\+cdrom' sources.list >/dev/null
		test $? -lt 1 && sed -i 's@deb\s\+cdrom.*@@'
		apt-get -y update
		for packages in vim curl gzip
		do
			echo -e "|\n|   Notice: Installing required package '$packages' via 'apt-get'"
			apt-get -y install $packages
		done
	elif [ -n "$(command -v yum)" ]; then 
		for packages in vim curl gzip
		do
			echo -e "|\n|   Notice: Installing required package '$packages' via 'yum'"
			yum -y install $packages
		done
	fi
}