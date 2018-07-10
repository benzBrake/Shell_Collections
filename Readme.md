# Ryan写的脚本合集
不全，不过大部份都会在这里存档，有些自己用的就放到Coding咯

:warning::  目前有问题，待更新

## Fail2ban
:warning:: fail2ban 一键安装脚本

## Nginx_Onekey
Nginx 一键安装脚本，不包含PHP MYSQL SQLITE

## ngx_google_deployment
Google 反代一键安装脚本，基于 Nginx_Onekey

## RyLLMP
lighttpd+mysql+sqlite+php 一键安装脚本
二进制安装，速度快

## supervisord
:warning:: Supervisor 一键安装脚本

## debian_squeeze_apt_sources.sh
Fix apt-get update 404 on debian squeeze
修复 Debian apt-get时报404错误
```shell
bash -c "$(wget https://raw.githubusercontent.com/benzBrake/Shell_Collections/master/debian_squeeze_apt_sources.sh -O -)"
```

## gdrive_cli.sh
Install prasmussen/gdrive automatic
一键安装 gdrive-cli
```shell
bash -c "$(wget https://raw.githubusercontent.com/benzBrake/Shell_Collections/master/gdrive_cli.sh -O -)"
```
## iptables_rules.sh
Useful iptables rules (not work on CentOS 7/RHEL 7)
```
bash -c "$(wget https://raw.githubusercontent.com/benzBrake/Shell_Collections/master/iptables_rules.sh -O -)"
```
