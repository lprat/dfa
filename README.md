# Dynamic analysis malicious files
*Analysis malicious files with virtualbox (Cuckoo/PIN/DynamoRIO).*

It's just docker file and scripts for automatise installation of cuckoo & guest vm analyz on virtualbox (tested on version 5.2). 
Docker dont protected you against exploit of virtualbox [cap_add == ALL && network mode host](if malware attack sandbox...), docker just for use cuckoo fast. Prefer use dedicate host system for this.

## Features
- Dockerz virtualbox & cuckoo (use x11 export or rdp to open virtualbox gui) [you must install vbox (same version for driver) on host system too for work!! It's not magic! Sorry]
- script for auto install VM for analyz from FREE ISO microsoft virtualbox (from microsoft website)
- cuckoo install with sysmon module + reverse nginx (ssl + auth htpasswd) + guacamol (remote control) + vmcloak + mitmproxy (view https trafic) + dnsmasq (view dns queries)

## Install & Run
- You must install same version of vbox driver on host system (last version of virtualbox 5.x)
- You configure docker-compose on cuckoo service
  - build environment (version of virtalbox)
  - environment for run (Password, image vb place [look volumes mount], ...) => choose vm guest install
- bash tcpdump_apparmor.sh && cd docker-cuckoo && docker-compose build && bash ../init_cuckoo.sh
- docker-compose up (read info log for instal vm) && bash ../network-cuckoo.sh
- Run you navigator on https://your_ip:8000 and play!

## If you dont play ... then Debug!
- All: docker-compose logs
- Virtualbox! ../virtualbox/vbrootconf/VBoxSVC.log

## Reference & Greetz
- Cuckoo Sandbox
- Pin Intel
- DynamoRIO
- blacktop (https://github.com/blacktop/docker-cuckoo/)
- T0ad (Thomas D.)
- https://infosecspeakeasy.org/t/howto-build-a-cuckoo-sandbox/27
- Vmcloak

## TODO
- Pin
- DynamoRIO
- Script for result analysis
  - check differents profils (admin/restricted user/...)
  - check coverage (dynamic vs static) call lib function with SFA (static analysis)
  - Create signatures for check detected IOC on infected system (yara => RAM & FILE | SIGMA => logs/mft/proxy/dns)
- Add Mitre Attack cuckoo Signatures
- Remake README for more explain use!

## Contact

lionel.prat9@gmail.com
