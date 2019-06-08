#!/bin/bash
#Reset cuckoo result
if docker ps -a|grep -i cuckoo; then echo " !!! Stop en remove docker contener cuckoo before start this script !!! ";exit -1;fi
SUDO=''
if [ "$(id -u)" != "0" ]; then
   SUDO=`which sudo`
   if test -z "$SUDO"; then 
    echo "This script must be run as root" 1>&2
    exit 1
   fi
fi
echo "Reset virtualbox..."
echo "Remove installed VM and configuration virtualbox in docker"
rm -rf virtualbox/vbcuckooconf/*
rm -rf virtualbox/vbox-guest/*
rm -rf virtualbox/vbrootconf/*
