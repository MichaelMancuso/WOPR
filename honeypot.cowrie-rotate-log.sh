#!/bin/bash

cd /opt/honeypots/cowrie-ssh
./stop.sh

cd /opt/honeypots/cowrie-ssh/log
# CURTIMESTAMP=`date +%Y-%m-%d-%H-%M-%S`
CURTIMESTAMP=`date +%Y-%m`

if [ ! -e archive ]; then
	mkdir archive
fi

/usr/bin/honeypot.show_log_stats.sh > archive/honeypot_stats.$CURTIMESTAMP.txt
cp archive/honeypot_stats.$CURTIMESTAMP.txt /usr/local/awstats/wwwroot/cgi-bin/
chown www-data.www-data /usr/local/awstats/wwwroot/cgi-bin/honeypot_stats.$CURTIMESTAMP.txt

tar -czf cowrie.log.$CURTIMESTAMP.tar.gz cowrie.log*

mv cowrie.log.$CURTIMESTAMP.tar.gz archive

rm cowrie.log*

cd /opt/honeypots/cowrie-ssh
sudo -u cowrie ./start.sh
