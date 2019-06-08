#/bin/bash
. venv/bin/activate && cuckoo community && deactivate
sudo service uwsgi restart
