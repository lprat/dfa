#!/bin/bash 

set -e

if VBoxManage list extpacks | grep -i 'Pack no. 0' ; then echo 'package vbox installed';else VBOX_VERSION=`dpkg -s virtualbox-5.2 | grep '^Version: ' | sed -e 's/Version: \([0-9\.]*\)\-.*/\1/'` ;wget http://download.virtualbox.org/virtualbox/${VBOX_VERSION}/Oracle_VM_VirtualBox_Extension_Pack-${VBOX_VERSION}.vbox-extpack ; echo "y" | sudo VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack-${VBOX_VERSION}.vbox-extpack;fi
if vboxmanage list hostonlyifs|grep '192.168.56.1'; then echo 'network OK';else echo 'create vboxnet0'; vboxmanage hostonlyif create; sudo ip link set dev vboxnet0 up;vboxmanage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0;vboxmanage dhcpserver modify --ifname vboxnet0 --disable; fi
if /sbin/ifconfig|grep 'vboxnet0'; then echo 'vboxnet0 UP'; else echo 'vboxnet0 put UP and set config';sudo ip link set dev vboxnet0 up; vboxmanage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0;vboxmanage dhcpserver modify --ifname vboxnet0 --disable;fi
#su cuckoo <<'EOF'
vboxmanage setproperty websrvauthlibrary null
vboxmanage setproperty machinefolder /guest
#put mitm proxy cert
cp /home/cuckoo/.mitmproxy/mitmproxy-ca-cert.p12 /home/cuckoo/.cuckoo/analyzer/windows/bin/cert.p12
cp /home/cuckoo/.mitmproxy/mitmproxy-ca-cert.p12 /install_guest/
cp /home/cuckoo/.mitmproxy/mitmproxy-ca-cert.cer /install_guest/
#put agent.py
cp /home/cuckoo/.cuckoo/agent/agent.py /install_guest/softwares/agent.py
#Put iptables rules if direct internet or proxy mode
echo "Go on host and run the script network.sh for add iptables rules FORWARD"
#read -p "When script finish, press enter:" -n1 -s
echo "When script finish, please create file /tmp/ok1: docker-compose exec cuckoo touch /tmp/ok1"
while [ ! -f /tmp/ok1 ]
do
  sleep 2
done
echo "start DNS service"
sudo service dnsmasq  start
#import image?
if [ -n "$CUCKOO_GUEST_IMAGE" ]; then
 if [ -n "$CUCKOO_GUEST_NAME" ]; then
  if vboxmanage list vms --long | grep -e ${CUCKOO_GUEST_NAME}; then
   echo "VM ${CUCKOO_GUEST_IMAGE} is already installed"
  else
   vboxmanage import ${CUCKOO_GUEST_IMAGE} --vsys 0 --vmname ${CUCKOO_GUEST_NAME}
   vboxmanage modifyvm ${CUCKOO_GUEST_NAME} --nic1 hostonly --hostonlyadapter1 vboxnet0
   if [ -n "$CUCKOO_SHARENAME" ]; then #use CUCKOO_SHARENAME if you need to install VM before use for cuckoo
    if [ -n "$CUCKOO_SHARE" ]; then
     echo "Add share on vm: ${CUCKOO_SHARENAME}"
     vboxmanage sharedfolder add ${CUCKOO_GUEST_NAME} --name ${CUCKOO_SHARENAME} --hostpath ${CUCKOO_SHARE} --automount
    fi
    #create script
    sed -i -E "s/ static 192\.168\.[0-9]+\.[0-9]+ 255\./ static $CUCKOO_GUEST_IP 255./g" ${CUCKOO_SHARE}/install.bat
    # -config network
    # -install python & cuckoo agent & need dependency
    # -install softwares & configure
    # -config windows
    echo "Start  VM: ${CUCKOO_GUEST_NAME}"
    vboxmanage startvm ${CUCKOO_GUEST_NAME} --type headless
    echo "Start proxy"
    mitmdump -p 8443 --ssl-insecure --mode transparent --ignore-hosts pypi.org --ignore-hosts files.pythonhosted.org &
    echo "Go on vm ${CUCKOO_GUEST_NAME} (docker-compose exec cuckoo virtualbox) and run the script \\${CUCKOO_SHARENAME}\install.bat and install office manually"
    #read -p "When script finish, press enter:" -n1 -s
    echo "When script finish, please create file /tmp/ok2: docker-compose exec cuckoo touch /tmp/ok2"
    while [ ! -f /tmp/ok2 ]
    do
      sleep 2
    done
    killall mitmdump
   fi
   vboxmanage snapshot ${CUCKOO_GUEST_NAME} take clean
   vboxmanage controlvm ${CUCKOO_GUEST_NAME} poweroff
   if [ -n "$CUCKOO_SHARE" ]; then
    vboxmanage sharedfolder remove ${CUCKOO_GUEST_NAME} --name ${CUCKOO_SHARENAME}
   fi
   vboxmanage snapshot ${CUCKOO_GUEST_NAME} restorecurrent
   VBoxManage modifyvm ${CUCKOO_GUEST_NAME} --vrdeport 5000-5050
   #add conf in virtualbox.conf
   if grep ${CUCKOO_GUEST_NAME} /home/cuckoo/.cuckoo/conf/virtualbox.conf; then
    echo "VM ${CUCKOO_GUEST_NAME} already present in cuckoo config"
   else
    sed -i -E "s/^(machines = .+)/\1,$CUCKOO_GUEST_NAME/g" /home/cuckoo/.cuckoo/conf/virtualbox.conf
    echo "[${CUCKOO_GUEST_NAME}]" >> /home/cuckoo/.cuckoo/conf/virtualbox.conf
    echo "label = ${CUCKOO_GUEST_NAME}" >> /home/cuckoo/.cuckoo/conf/virtualbox.conf
    if [ -n "$CUCKOO_PLATEFORM" ]; then
     echo "platform = ${CUCKOO_PLATEFORM}" >> /home/cuckoo/.cuckoo/conf/virtualbox.conf
    fi
    if [ -n "$CUCKOO_GUEST_IP" ]; then
     echo "ip = ${CUCKOO_GUEST_IP}" >> /home/cuckoo/.cuckoo/conf/virtualbox.conf
    fi
    echo "snapshot = clean" >> /home/cuckoo/.cuckoo/conf/virtualbox.conf
    echo "interface = vboxnet0" >> /home/cuckoo/.cuckoo/conf/virtualbox.conf
    echo "tags =" >> /home/cuckoo/.cuckoo/conf/virtualbox.conf
    echo "options =" >> /home/cuckoo/.cuckoo/conf/virtualbox.conf
   fi
  fi
 fi
fi
#vboxwebsrv --background -H 127.0.0.1
#UPDATE cuckoo community
echo "Update cuckoo community..."
. venv/bin/activate && cuckoo community && deactivate
#Add authentification password
echo "add password WEB: admin/$WEBPASS"
htpasswd -b -c /home/cuckoo/.passwdweb admin $WEBPASS
echo "add password API: admin/$APIPASS"
htpasswd -b -c /home/cuckoo/.passwdapi admin $APIPASS
#run service
sudo systemctl start glances.service
sudo service dnsmasq start
sudo service guacd start
sudo service nginx start
sudo service cron start
sudo service uwsgi start
#if error, run: . venv/bin/activate && cuckoo --debug
/bin/bash
