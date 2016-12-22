#/bin/bash
prep () {
	echo "$1" | sed -e 's/^ *//g' -e 's/ *$//g' | sed -n '1 p'
}
#Clear Rules
FLT_TABLES="filter nat mangle"
for PT in $FLT_TABLES
do
	iptables -t $PT -F
	iptables -t $PT -X
	iptables -t $PT -Z
done
#Accept local loop
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
#No Spam
iptables -A INPUT -p tcp -m multiport --dport 25,110,465:587,993:995 -j DROP
iptables -A INPUT -p udp -m multiport --dport 25,110,465:587,993:995 -j DROP
iptables -A OUTPUT -p tcp -m multiport --dport 25,110,465:587,993:995 -j DROP
iptables -A OUTPUT -p udp -m multiport --dport 25,110,465:587,993:995 -j DROP
#
nic=$(prep "$(ip route get 8.8.8.8 | grep dev | awk -F'dev' '{ print $2 }' | awk '{ print $1 }')")
if [ -z $nic ]
then
	nic=$(prep "$(ip link show | grep 'eth[0-9]' | awk '{ print $2 }' | tr -d ':')")
fi
IPV4=$(ip addr show $nic | grep 'inet ' | awk '{ print $2 }' | awk -F\/ '{ print $1 }' | grep -v '^127' | awk '{ print $0 } END { if (!NR) print "N/A" }')
for ip in ${IPV4}
do
	iptables -I INPUT -d ${ip}/32 -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,URG RST -j DROP
done
# ICMP
AICMP="8"
for P_ICMP in $AICMP
do
	iptables -A INPUT -p icmp --icmp-type $P_ICMP  -j ACCEPT
done
# 80 443 HTTPS? SSH
SSH_PORTS=$(netstat -ntlp|grep sshd |awk -F: '{if($4!="")print $4}')
for port in ${SSH_PORTS}
do
	iptables -A INPUT -m state --state NEW -p tcp --dport $port -j ACCEPT
done
iptables -A INPUT -m state --state NEW -p tcp -m multiport --dport 80,443 -j ACCEPT
iptables -A INPUT -j REJECT --reject-with icmp-port-unreachable
iptables -A FORWARD -j REJECT --reject-with icmp-port-unreachable
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
DNS_SERVER=$(awk '/^nameserver/{print $2}' /etc/resolv.conf)
for dns in $DNS_SERVER
do
	iptables -A OUTPUT -d ${dns}/32 -p udp -m udp --dport 53 -j ACCEPT
done
iptables -A OUTPUT -p udp -j REJECT --reject-with icmp-port-unreachable