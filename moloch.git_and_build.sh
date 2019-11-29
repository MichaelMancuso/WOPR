#!/bin/bash

cd /opt

git clone https://github.com/aol/moloch.git moloch

cd moloch

sed -i "s|PFRING=6.0.2|PFRING=6.0.3|" easybutton-build.sh
sed -i "s|PCAP=1.7.2|PCAP=1.7.4|" easybutton-build.sh

apt-get -y install libnuma-dev

./easybutton-singlehost.sh
