#/bin/bash
#
# Install gdrive-cli
# Author: Char1sma<github-char1sma@woai.ru>
# Date: 2016-12-02
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
if [ -f ~/bin/gdrive ]; then
	exit 0
else
	MACHINE_TYPE=`uname -m`
	if [ ${MACHINE_TYPE} == 'x86_64' ]; then
		MACHINE_TYPE=386
	else
		MACHINE_TYPE=x64
	fi
	DOWNLOAD_URL=`wget -O- https://github.com/prasmussen/gdrive  2>/dev/null | grep "<a.*gdrive-linux-${MACHINE_TYPE}" | sed 's/.*href="//' | sed 's/&amp.*//'`
	mkdir -p ~/bin
	wget ${DOWNLOAD_URL} -O ~/bin/gdrive
	chmod +x ~/bin/gdrive
fi