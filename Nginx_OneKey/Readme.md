# Nginx_OneKey
Install nginx onekey.
## Usage:
```shell
wget --no-check-certificate https://github.com/Char1sma/Shell_Collections/raw/master/Nginx_OneKey/onekey.sh
bash onekey.sh install | tee -a nginx_onekey.log
```
## Important Instruction
- Initial configure does not require SSL/HTTPS.This means you can only access your web by HTTP in the beginning.By the way,you can deploy your SSL/HTTPS upon this project.
- Configure document is "/etc/nginx/nginx.conf".
- Start nginx by using "/etc/nginx/sbin/nginx" / ("/etc/nginx/sbin/nginx -s reload") / ("/etc/nginx/sbin/nginx -s stop").

## Depend on Projects
- [Nginx](http://nginx.org/ "Nginx")
- [ngx_http_substitutions_filter_module](https://github.com/yaoweibin/ngx_http_substitutions_filter_module "ngx_http_substitutions_filter_module")