#!/bin/bash

echo "[`date`] Getting honeyd..."
cd /opt/honeypots/

git clone git://github.com/DataSoft/Honeyd.git honeyd

echo "[`date`] Installing dependencies..."
apt-get -y install automake libtool libdumbnet-dev libedit-dev git build-essential libcap2-bin libann-dev libpcap0.8-dev libboost-program-options-dev libboost-serialization-dev sqlite3 libsqlite3-dev libcurl3 libcurl4-gnutls-dev iptables libboost-system-dev libboost-filesystem-dev libevent-dev libprotoc-dev protobuf-compiler liblinux-inotify2-perl libfile-readbackwards-perl

echo "[`date`] making..."

cd honeyd
./autogen.sh
automake
./configure
make
make install
echo "[`date`] Done with honeyd.  Building nova..."

apt-get -y install libboost-chrono-dev libboost-date-time-dev libboost-dev libboost-filesystem-dev libboost-iostreams-dev libboost-iostreams-dev libboost-program-options-dev libboost-regex-dev libboost-serialization-dev libboost-system-dev libboost-test-dev libboost-thread-dev

cd /opt/honeypots
git clone https://github.com/DataSoft/Nova.git nova
cd nova
autoconf
./configure
make
make install
