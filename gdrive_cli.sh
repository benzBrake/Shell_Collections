#/bin/bash
#
# Install gdrive-cli
# Author: benzBrake<github-benzBrake@woai.ru>
# Date: 2017-01-22
if [ -f ~/bin/gdrive ]; then
	exit 0
else
	MACHINE_TYPE=$(uname -m)
	if [ ${MACHINE_TYPE} == 'x86_64' ]; then
		MACHINE_TYPE=386
	else
		MACHINE_TYPE=x64
	fi
	DOWNLOAD_URL=$(wget -O- https://github.com/prasmussen/gdrive  2>/dev/null | grep "<a.*gdrive-linux-${MACHINE_TYPE}" | sed 's/.*href="//' | sed 's/&amp.*//')
	mkdir -p ~/bin
	wget ${DOWNLOAD_URL} -O ~/bin/gdrive
	chmod +x ~/bin/gdrive
	echo ${PATH} | grep "${HOME}/bin"
	if [ "$?" -ne "0" ]; then
		echo "export PATH=$PATH:~/bin" >> "$HOME/$(echo ${SHELL} | sed 's@.*/@.@')rc"
	fi
fi
