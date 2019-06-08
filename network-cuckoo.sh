#/bin/bash
SUDO=''
if [ "$(id -u)" != "0" ]; then
   SUDO=`which sudo`
   if test -z "$SUDO"; then 
    echo "This script must be run as root" 1>&2
    exit 1
   fi
fi

if [ -n "$1" ]; then
 if $SUDO iptables -t nat -C POSTROUTING -o $1 -i vboxnet0 -s 192.168.56.0/24 -j MASQUERADE; then 
  echo "Rule: iptables -t nat -A POSTROUTING -o $1 -i vboxnet0 -s 192.168.56.0/24 -j MASQUERADE -- OK"
 else 
  echo "Add rule: iptables -t nat -A POSTROUTING -o $1 -i vboxnet0 -s 192.168.56.0/24 -j MASQUERADE"
  $SUDO iptables -t nat -A POSTROUTING -o $1 -i vboxnet0 -s 192.168.56.0/24 -j MASQUERADE
 fi
else
  echo "Syntaxe: sudo ./network.sh eth0"
  echo "Indicate interface network in first parameter."
  exit -1
fi
# Default drop.
#iptables -P FORWARD DROP
if $SUDO iptables -t nat -C PREROUTING -i vboxnet0 -p tcp -m tcp --dport 80 -j DNAT --to-destination 192.168.56.1:8443; then 
 echo "Rule: iptables -t nat -A PREROUTING -i vboxnet0 -p tcp -m tcp --dport 80 -j DNAT --to-destination 192.168.56.1:8443 -- OK"
else 
 echo "Add rule: iptables -t nat -A PREROUTING -i vboxnet0 -p tcp -m tcp --dport 80 -j DNAT --to-destination 192.168.56.1:8443"
 $SUDO iptables -t nat -A PREROUTING -i vboxnet0 -p tcp -m tcp --dport 80 -j DNAT --to-destination 192.168.56.1:8443
fi

if $SUDO iptables -t nat -C PREROUTING -i vboxnet0 -p tcp -m tcp --dport 443 -j DNAT --to-destination 192.168.56.1:8443; then 
 echo "Rule: iptables -t nat -A PREROUTING -i vboxnet0 -p tcp -m tcp --dport 443 -j DNAT --to-destination 192.168.56.1:8443 -- OK"
else 
 echo "Add rule: iptables -t nat -A PREROUTING -i vboxnet0 -p tcp -m tcp --dport 443 -j DNAT --to-destination 192.168.56.1:8443"
 $SUDO iptables -t nat -A PREROUTING -i vboxnet0 -p tcp -m tcp --dport 443 -j DNAT --to-destination 192.168.56.1:8443
fi

if $SUDO iptables -t nat -C PREROUTING -i vboxnet0 -p tcp -m tcp --dport 53 -j DNAT --to-destination 192.168.56.1:53; then 
 echo "Rule: iptables -t nat -A PREROUTING -i vboxnet0 -p tcp -m tcp --dport 53 -j DNAT --to-destination 192.168.56.1:53 -- OK"
else 
 echo "Add rule: iptables -t nat -A PREROUTING -i vboxnet0 -p tcp -m tcp --dport 53 -j DNAT --to-destination 192.168.56.1:53"
 $SUDO iptables -t nat -A PREROUTING -i vboxnet0 -p tcp -m tcp --dport 53 -j DNAT --to-destination 192.168.56.1:53
fi

if $SUDO iptables -t nat -C PREROUTING -i vboxnet0 -p udp -m udp --dport 53 -j DNAT --to-destination 192.168.56.1:53; then 
 echo "Rule: iptables -t nat -A PREROUTING -i vboxnet0 -p udp -m udp --dport 53 -j DNAT --to-destination 192.168.56.1:53 -- OK"
else 
 echo "Add rule: iptables -t nat -A PREROUTING -i vboxnet0 -p udp -m udp --dport 53 -j DNAT --to-destination 192.168.56.1:53"
 $SUDO iptables -t nat -A PREROUTING -i vboxnet0 -p udp -m udp --dport 53 -j DNAT --to-destination 192.168.56.1:53
fi

# Existing connections.
if $SUDO iptables -C FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT; then 
 echo "Rule: iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT -- OK"
else 
 echo "Add rule: iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT"
 $SUDO iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
fi

if $SUDO iptables -C FORWARD -o $1 -i vboxnet0 -s 192.168.56.0/24 -m state --state NEW -j ACCEPT; then 
 echo "Rule: iptables -A FORWARD -o $1 -i vboxnet0 -s 192.168.56.0/24 -m state --state NEW -j ACCEPT -- OK"
else 
 echo "Add rule: iptables -A FORWARD -o $1 -i vboxnet0 -s 192.168.56.0/24 -m state --state NEW -j ACCEPT"
 $SUDO iptables -A FORWARD -o $1 -i vboxnet0 -s 192.168.56.0/24 -m state --state NEW -j ACCEPT
fi

if $SUDO iptables -C FORWARD -s 192.168.56.0/24 -d 192.168.56.0/24 -j ACCEPT; then 
 echo "Rule: iptables -A FORWARD -s 192.168.56.0/24 -d 192.168.56.0/24 -j ACCEPT -- OK"
else 
 echo "Add rule: iptables -A FORWARD -s 192.168.56.0/24 -d 192.168.56.0/24 -j ACCEPT"
 $SUDO iptables -A FORWARD -s 192.168.56.0/24 -d 192.168.56.0/24 -j ACCEPT
fi

if sysctl -w net.ipv4.ip_forward=1 | grep 'net.ipv4.ip_forward = 1'; then 
 echo "Sysctl net.ipv4.ip_forward=1 OK"
else 
 echo "Change sysctl net.ipv4.ip_forward=1"
 sysctl -w net.ipv4.ip_forward=1
fi
# Log stuff that reaches this point (could be noisy).
#iptables -A FORWARD -j LOG

