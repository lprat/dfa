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
echo "Reset cuckoo result..."
echo "Remove mongo & postgres datas"
$SUDO rm -rf cuckoo/mongo-data
$SUDO rm -rf cuckoo/postgres-data
echo "Remove storage cuckoo"
$SUDO rm -rf cuckoo/storage/analyses/*
$SUDO rm -rf cuckoo/storage/baseline/*
$SUDO rm -rf cuckoo/storage/binaries/*
echo "Remove temp cuckoo"
$SUDO rm -rf cuckoo/cuckoo-tmp/*
