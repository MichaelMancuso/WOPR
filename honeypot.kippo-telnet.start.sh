#!/bin/bash

# Source is from git: git clone https://github.com/hiviah/kippo-telnet.git cowrie-telnet

# Don't forget to update the data/userdb.txt file to remove the default passwords

cd /opt/honeypots/kippo-telnet
sudo -u cowrie ./start.sh
