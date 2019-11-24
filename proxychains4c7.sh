#!/usr/bin/env bash
cat >&1<<EOF
# 一键安装 Proxychains
# By Ryan<github-benzBrake@woai.ru>
# 
# 错误代码
# 1 没有 root 权限
# 2 不是 RHEL/CentOS
# 3.无法下载 Proxychains 源码
# 4.编译安装失败
EOF
read -n 1 -p "Press any key to continue(or CTRL+C to exit)..."
[[ $EUID -ne 0 ]] && exit 1
[[ -z $(command -v yum) ]] && exit 2
yum -y install git gcc automake autoconf libtool make
cd /tmp
git clone https://github.com/rofl0r/proxychains-ng.git
[[ $?-ne 0 ]] && exit 3
cd proxychains-ng
./configure
[[ $?-ne 0 ]] && exit 4
make && make install
[[ $?-ne 0 ]] && exit 4
cp ./src/proxychains.conf /etc/proxychains.conf
cd .. && rm -rf proxychains-ng
echo "All Things Done!"
