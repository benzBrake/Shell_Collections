#!/usr/bin/env bash
test -z "$WORKING_DIR" && WORKING_DIR=$( pwd )
help_info() {
    echo "Usage: $(basename $0) [OPTION]"
    echo "Supervisor installer"
    echo "Example: $(basename $0) -i"
    echo ""
    echo "OPTIONs"
    echo "  -i,--install		install supervisor"
    echo "  -u,--uninstall	uninstall supervisor"
    echo "  -g,--geturl	ouput config url"
    echo ""
    echo "Report bugs to benzBrake<benzBrake@woai.ru>"
}
get_config_file() {
    if [ -n "$(command -v systemctl)" ]; then
        systemctl cat supervisor > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            CONF=$(systemctl cat supervisord | grep ExecStart | sed 's@.*\s@@')
        else
            CONF=$(systemctl cat supervisor | grep conf)
            if [ -z "$CONF" ]; then
                CONF=$(cat /etc/init.d/supervisor* | egrep "supervisor([a-z])?.conf" | sed 's@\.conf.*@.conf@;s@.*\s@@')
            else
                CONF=$(systemctl cat supervisor | grep ExecStart | sed 's@.*\s@@')
            fi
        fi
        if [ -z "$CONF" ]; then
            CONF=$(cat /etc/init.d/supervisor* | egrep "supervisor([a-z])?.conf" | sed 's@\.conf.*@.conf@;s@.*\s@@')
        fi
        echo "$CONF"
    else
        cat /etc/init.d/supervisor* | egrep "supervisor([a-z])?.conf" | sed 's@\.conf.*@.conf@;s@.*\s@@'
    fi
    exit
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
    -g|--geturl)
        get_config_file
        shift
    ;;
    *)
        ERROR=yes
        shift
    ;;
    esac 
done
[ -z "$action" ] && {
    help_info
    exit 0
}
if [ -z "$ERROR" ]; then
    if [ "$FLAG" == "install" ]; then
        if [ -n "$(command -v supervisorctl)" ]; then
            echo "You have install supervisor!"
            exit 1
            service supervisord start
        fi
        if [ -n "$(command -v apt-get)" ]; then
            apt-get update
            apt-get -y install supervisor egrep
        else
            if [ -n "$(command -v yum)" ]; then
                if [ -n "$(command -v systemctl)" ]; then
                    yum -y install epel-release
                    yum -y install supervisor
                    systemctl enable supervisor
                    ystemctl start supervisor
                    systemctl enable supervisord
                    systemctl start supervisord
                else
                    yum -y install python-pip
                    pip install meld3==0.6.7
                    pip install supervisor
                    mkdir -pv /etc/supervisor/conf.d /var/log/supervisor/
                    wget --no-check-certificate https://raw.githubusercontent.com/benzBrake/Shell_Collections/master/supervisord/supervisord.conf -O /etc/supervisor/supervisord.conf
                    [ ! -f /etc/init.d/supervisord ] && {
                        wget --no-check-certificate https://raw.githubusercontent.com/benzBrake/Shell_Collections/master/supervisord/supervisord -O /etc/init.d/supervisord
                        chmod +x /etc/init.d/supervisord
                        chkconfig --add supervisord
                        chkconfig supervisord on
                        /etc/init.d/supervisord start
                    }
                fi
            fi
        fi
        echo "[INFO] Install Supervisor successful."
        echo " Config file: $(get_config_file)"
    elif [ "$FLAG" == "uninstall" ]; then
        if [ -n "$(command -v apt-get)" ]; then
            apt-get -y remove --purge supervisor
        elif [ -n "$(command -v yum)" ]; then
            if [ -n "$(command -v systemctl)" ]; then
                yum -y remove supervisor
            else
                /etc/init.d/supervisord stop
                chkconfig --del supervisord
                echo "y" | pip uninstall supervisor
            fi
            rm -rf /etc/init.d/supervisor*
        fi
        rm -rf $(get_config_file)
        echo "[INFO] Uninstall Supervisor successful."
    fi
else
    echo "Parameter error [$action]"
    echo "=========================================="
    help_info
fi