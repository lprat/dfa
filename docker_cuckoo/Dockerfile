#Docker DFA: Dynamic File Analysis on virtualbox
#reference:  https://infosecspeakeasy.org/t/howto-build-a-cuckoo-sandbox/27 && Doc Thomas D. alias t0ad && https://cuckoo.sh/docs/installation/index.html && https://github.com/blacktop/docker-cuckoo/
FROM debian:stretch
MAINTAINER Lionel PRAT <lionel.prat9@gmail.com>

#env vbox
ARG VBOX_VER=5.2
#TODO suricata for cuckoo
#https://401trg.com/using-emergingthreats-suricata-ruleset-to-scan-pcap/
#suricata & python3 & pip3 install pyyaml && wget https://github.com/401trg/utilities/blob/master/suricata_et_rule_update.py && python3 suricata_et_rule_update.py
RUN apt-get update && apt-get install --no-install-recommends -y python python-pip python-dev libffi-dev libssl-dev python-setuptools libjpeg-dev zlib1g-dev swig python-libvirt tcpdump libcap2-bin git nano vim pcregrep libpcre++-dev build-essential automake libtool flex bison swig ssdeep libfuzzy-dev libfuzzy2 uwsgi uwsgi-plugin-python apache2-utils nginx libguac-client-rdp0 libguac-client-vnc0 libguac-client-ssh0 guacd libjansson-dev libmagic-dev wget gnupg2 procps net-tools netcat sudo samba-common-bin dnsmasq libpq-dev cron host
RUN apt-get install --no-install-recommends -y libjansson-dev libmagic-dev liblzma-dev pkg-config libvirt-dev genisoimage

############### Install VirtualBox: https://github.com/Jencryzthers/VboxInsideDocker
RUN wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox_2016.asc -O- | apt-key add -
RUN sh -c 'echo "deb http://download.virtualbox.org/virtualbox/debian stretch contrib" >> /etc/apt/sources.list.d/virtualbox.list'
RUN echo "deb http://http.debian.net/debian unstable main" >> /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y virtualbox-$VBOX_VER
RUN apt-get install -y -f
RUN rm -rf /var/lib/apt/lists/*

# Install Virtualbox Extension Pack
RUN VBOX_VERSION=`dpkg -s virtualbox-$VBOX_VER | grep '^Version: ' | sed -e 's/Version: \([0-9\.]*\)\-.*/\1/'` ; \
    wget http://download.virtualbox.org/virtualbox/${VBOX_VERSION}/Oracle_VM_VirtualBox_Extension_Pack-${VBOX_VERSION}.vbox-extpack ; \
    VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack-${VBOX_VERSION}.vbox-extpack ; \
    rm Oracle_VM_VirtualBox_Extension_Pack-${VBOX_VERSION}.vbox-extpack
############### end virtual box

RUN rm -rf /var/lib/apt/lists/*

##################Cuckoo install
#RUN mkdir /tmp/guac-build && cd /tmp/guac-build && wget https://www.apache.org/dist/guacamole/1.0.0/source/guacamole-server-1.0.0.tar.gz && tar xvf guacamole-server-1.0.0.tar.gz && cd guacamole-server-1.0.0 && ./configure --with-init-dir=/etc/init.d && make && make install && cd .. && ldconfig
RUN git clone https://github.com/VirusTotal/yara
RUN cd yara && ./bootstrap.sh && ./configure --enable-cuckoo --enable-magic --enable-dotnet && make && make install
RUN useradd -ms /bin/bash cuckoo && usermod -L cuckoo && usermod -a -G vboxusers cuckoo && usermod -a -G www-data cuckoo
#&& usermod -a -G kvm cuckoo && usermod -a -G libvirt cuckoo 
RUN groupadd pcap && usermod -a -G pcap cuckoo && chgrp pcap /usr/sbin/tcpdump
RUN setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump
RUN pip install -U virtualenv wheel
RUN mkdir /etc/nginx/certs && cd /etc/nginx/certs && openssl req -x509 -nodes -days 1095 -new -sha256 -newkey rsa:4096 -keyout cuckoo-soc.key -out cuckoo-soc.crt -batch && openssl dhparam -out dhparams.pem 4096
COPY nginx.conf /etc/nginx/nginx.conf
COPY cuckoo-services /etc/nginx/sites-available/cuckoo-services
USER cuckoo
WORKDIR /home/cuckoo
#mitmproxy prepare
RUN mkdir .mitmproxy
RUN virtualenv venv
#weasyprint require python3
RUN . venv/bin/activate && pip install -U setuptools psycopg2 m2crypto backports.lzma libvirt-python pydeep xmltodict
RUN . venv/bin/activate && pip install -U git+https://github.com/VirusTotal/yara-python
RUN . venv/bin/activate && pip install -U git+https://github.com/kbandla/pydeep.git
RUN . venv/bin/activate && pip install -U pillow distorm3 pycrypto openpyxl ujson vmcloak
RUN . venv/bin/activate && pip install -U git+https://github.com/volatilityfoundation/volatility.git
RUN . venv/bin/activate && pip install -U cuckoo cuckoo-api httpreplay
RUN . venv/bin/activate && cuckoo && cuckoo community && vmcloak
RUN . venv/bin/activate && cuckoo web --uwsgi | sed 's/localhost:8000/0.0.0.0:8000/g' > /home/cuckoo/cuckoo-web.ini
RUN . venv/bin/activate && cuckoo api --uwsgi | sed 's/localhost:8090/0.0.0.0:8090/g' > /home/cuckoo/cuckoo-api.ini
#run in entrypoint
#RUN . venv/bin/activate && vboxmanage hostonlyif create && vboxmanage hostonlyif ipconfig vboxnet0 --ip 192.168.2.1 && vboxmanage setproperty machinefolder /guest
USER root
#install mitm proxy -- https://mitmproxy.org/downloads/
RUN wget https://snapshots.mitmproxy.org/4.0.4/mitmproxy-4.0.4-linux.tar.gz && tar -zxf mitmproxy-4.0.4-linux.tar.gz && rm mitmproxy-4.0.4-linux.tar.gz && mv mitm* /usr/local/bin/
#conf dnsmasq
COPY dnsmasq.conf /etc/dnsmasq.conf
COPY update.sh /usr/local/bin/update.sh
COPY cron_update /etc/cron.d/cron_update
#MAJ cuckoo comunity by crontab
RUN chmod +x /usr/local/bin/update.sh && chmod 0644 /etc/cron.d/cron_update && crontab /etc/cron.d/cron_update
RUN cp /home/cuckoo/cuckoo-web.ini /etc/uwsgi/apps-enabled/cuckoo-web.ini && cp /home/cuckoo/cuckoo-api.ini /etc/uwsgi/apps-enabled/cuckoo-api.ini
RUN echo 'processes = 1' >> /etc/uwsgi/apps-enabled/cuckoo-web.ini && echo 'threads = 4' >> /etc/uwsgi/apps-enabled/cuckoo-web.ini
EXPOSE 8000
EXPOSE 8090
#linux-headers-amd64 linux-headers-4.4.0-1-amd64
RUN rm /etc/nginx/sites-enabled/default
RUN usermod -a -G sudo cuckoo
RUN usermod -a -G www-data cuckoo
RUN usermod -a -G cuckoo www-data
RUN echo 'cuckoo ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/cuckoo
COPY cuckoo.service /etc/systemd/system/cuckoo.service
RUN systemctl enable cuckoo.service
COPY cuckoo-services /etc/nginx/sites-enabled/cuckoo-services
COPY cuckoo-services /etc/nginx/sites-available/cuckoo-services
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod 755 /docker-entrypoint.sh
#add sysmon https://github.com/cuckoosandbox/cuckoo/pull/2518/files
COPY sysmon/aux/sysmon.py ./venv/lib/python2.7/site-packages/cuckoo/data/analyzer/windows/modules/auxiliary/sysmon.py
COPY sysmon/proc/sysmon.py ./venv/lib/python2.7/site-packages/cuckoo/processing/sysmon.py
COPY config.patch /tmp/config.patch
RUN patch ./venv/lib/python2.7/site-packages/cuckoo/common/config.py < /tmp/config.patch
RUN chown cuckoo.cuckoo ./venv/lib/python2.7/site-packages/cuckoo/data/analyzer/windows/modules/auxiliary/sysmon.py && chmod 644 ./venv/lib/python2.7/site-packages/cuckoo/data/analyzer/windows/modules/auxiliary/sysmon.py
RUN chown cuckoo.cuckoo ./venv/lib/python2.7/site-packages/cuckoo/processing/sysmon.py && chmod 644 ./venv/lib/python2.7/site-packages/cuckoo/processing/sysmon.py
USER cuckoo
RUN echo '[sysmon]' >> /home/cuckoo/.cuckoo/conf/auxiliary.conf && echo 'enabled = {{ auxiliary.sysmon.enabled }}' >> /home/cuckoo/.cuckoo/conf/auxiliary.conf && echo '[sysmon]' >> /home/cuckoo/.cuckoo/conf/processing.conf && echo 'enabled = {{ processing.sysmon.enabled }}' >> /home/cuckoo/.cuckoo/conf/processing.conf
#fix mitm log: https://github.com/cuckoosandbox/cuckoo/pull/2104/files
##################End Cuckoo install
ENTRYPOINT ["/docker-entrypoint.sh"]

#TODO
# -create script install drltrace and run 
# -install pin tools
