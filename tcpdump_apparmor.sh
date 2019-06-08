#!/bin/bash
if [ -f /etc/apparmor.d/usr.sbin.tcpdump ]
then
  echo "Disable apparmor on TCPDUMP"
  sudo apt-get install -y apparmor-utils
  sudo aa-disable /usr/sbin/tcpdump
fi
