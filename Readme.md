# Ryan 写的脚本合集

不全，不过大部份都会在这里存档，有些自己用的就放到 Coding 咯

:warning:: 目前有问题，待更新

## CloudTorrent

安装 CloudTorrent BT 离线下载工具

## Fail2ban

:warning:: fail2ban 一键安装脚本

## Nginx_Onekey

Nginx 一键安装脚本，不包含 PHP MYSQL SQLITE

## ngx_google_deployment

Google 反代一键安装脚本，基于 Nginx_Onekey

## RyLLMP

lighttpd+mysql+sqlite+php 一键安装脚本
二进制安装，速度快

## supervisord

:warning:: Supervisor 一键安装脚本

## debian_squeeze_apt_sources.sh

Fix apt-get update 404 on debian squeeze
修复 Debian apt-get 时报 404 错误

```shell
bash -c "$(wget https://raw.githubusercontent.com/benzBrake/Shell_Collections/master/debian_squeeze_apt_sources.sh -O -)"
```

## jotta_cli.sh

Install Jotta-cli tools automatic
一键安装 Jotta-cli

```shell
bash -c "$(wget https://raw.githubusercontent.com/benzBrake/Shell_Collections/master/jotta_cli.sh -O -)"
```

## gdrive_cli.sh

Install prasmussen/gdrive automatic
一键安装 gdrive-cli

```shell
bash -c "$(wget https://raw.githubusercontent.com/benzBrake/Shell_Collections/master/gdrive_cli.sh -O -)"
```

## iptables_rules.sh

Useful iptables rules (not work on CentOS 7/RHEL 7)

```shell
bash -c "$(wget https://raw.githubusercontent.com/benzBrake/Shell_Collections/master/iptables_rules.sh -O -)"
```

## rclone-mount.sh

RCLONE 辅助挂载脚本

先安装 fuse 和 fuse3

```shell
apt update
apt install fuse fuse3
```

然后下载此脚本，比如下载到`/data/rclone`下，然后修改脚本

```shell
#--Config Start
BIN="/usr/bin/rclone"  # rclone 路径
CONFIG="/data/rclone/rclone.conf" # rclone 配置文件
LOG_PATH="/var/log/rcloned.log" # rclone 日志路径
MOUNT_LIST="/data/rclone/mount.conf" # 挂载列表
#--Config End
```

`mount.conf`格式如下

```
配置名:=挂载路径
```

比如我的配置如下

```shell
# rclone config
Current remotes:

Name                 Type
====                 ====
dy001                onedrive
```

`mount.conf`的格式如下
如果想暂时不挂载，添加#靠头即可

```
# local=googleone:=/mnt/googleone 这是注释示例
webdav=jotta:/=0.0.0.0:19797=root:1234
local=115:=/mnt/115
```

然后运行脚本即可

```shell
sh rclone-mount.sh start
```

## tcping.sh

一键安装支持 ipv4/ipv6 双栈的 tcping

```bash
curl -sSL https://raw.githubusercontent.com/benzBrake/Shell_Collections/master/tcping.sh | sh
```

## openwrt-install-clouddrive2.sh

openwrt 环境一键安装 clouddrive2

curl -sSL https://raw.githubusercontent.com/benzBrake/Shell_Collections/master/openwrt-install-clouddrive2.sh | bash
