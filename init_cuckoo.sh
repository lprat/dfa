#!/bin/bash
#mkdir guest/softwares
#https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/
#https://developer.microsoft.com/fr-fr/windows/downloads/virtual-machines
#clean
#rm virtualbox/IMG_VIRTUALBOX/*.ova
rm cuckoo/guest/softwares/agent.py
rm cuckoo/guest/*.p12
rm cuckoo/guest/*.cer
if [ "$(ls -A virtualbox/IMG_VIRTUALBOX/)" ]; then
 echo "Folder contains ova is not empty: virtualbox/IMG_VIRTUALBOX/"
else
 echo "Download Windows Image"
 wget -i data/OVAs -P virtualbox/IMG_VIRTUALBOX/
fi

if [ "$(ls -A cuckoo/guest/softwares/)" ]; then
 echo "Folder contains software for windows install is not empty: cuckoo/guest/softwares/"
else
 echo "Download software for windows"
 wget -i data/URLs -P cuckoo/guest/softwares/
 cd cuckoo/guest/softwares/ && unzip Sysmon.zip && rm Sysmon.zip
fi

echo "Get configuration for vmcloak and mitmproxy"
rm -rf cuckoo/mitmproxy/ 
rm -rf cuckoo/vmcloak-conf/
docker run -d --name tmpdfa --rm --entrypoint /usr/local/bin/mitmdump lprat/dfa
docker cp -a tmpdfa:/home/cuckoo/.mitmproxy/ cuckoo/mitmproxy/ 
docker cp -a tmpdfa:/home/cuckoo/.vmcloak/ cuckoo/vmcloak-conf/
docker stop tmpdfa

cat <<EOF > cuckoo/mitmproxy/config.yaml
listen_host: 192.168.56.1
#mode: "transparent"
#mode: upstream:http://proxy:port
showhost: True
ciphers_client: "ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES
128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:
ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS"
EOF

chmod 644 cuckoo/mitmproxy/config.yaml
