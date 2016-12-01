#/bin/bash
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
# ICMP
AICMP="0 3 3/4 4 8 11 12 14 16 18"
for P_ICMP in $AICMP
do
	iptables -A INPUT -p icmp --icmp-type $P_ICMP  -j ACCEPT
done
# 80 443 HTTPS? SSH
SSH_PORT=`netstat -ntlp|grep sshd |awk -F: '{if($4!="")print $4}' | head -n 1 | sed 's/ //'`
iptables -A INPUT -p tcp --dport $SSH_PORT --sport 1024:65534 -j ACCEPT
iptables -A INPUT -p tcp -m multiport --dport 80,443 --sport 1024:65534 -j ACCEPT
iptables -P INPUT DROP
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT