#!/bin/bash

# References: 
# http://terminal28.com/how-to-block-countries-using-iptables-debian/
# https://blog.ls20.com/iptables-geoip-port-knocking-and-port-scan-detection/
# http://blog.jeshurun.ca/technology/block-countries-ubuntu-iptables-xtables-geoip

apt-get -y install libtext-csv-xs-perl geoip-database libgeoip1
apt-get install iptables iptables-dev module-assistant xtables-addons-common libtext-csv-xs-perl unzip


module-assistant --verbose --text-mode auto-install xtables-addons
# apt-get -y install xtables-addons-dkms

if [ $? -gt 0 ]; then
	echo "module-assistant failed.  This happens.  Do this:"
	echo "nano /usr/src/modules/xtables-addons/mconfig"
	echo "Remove the m from CHAOS, DNETMAP, RAWNAT, SYSRQ, TARPIT, CONDITION, FUZZY, XTLENGTH2,PKNOCK, QUOTA2"
	echo "chattr +i /usr/src/modules/xtables-addons/mconfig"
	echo ""
	echo "Then rerun this script."
	exit 1
fi

mkdir /usr/share/xt_geoip
cd /usr/share/xt_geoip
/usr/lib/xtables-addons/xt_geoip_dl
/usr/lib/xtables-addons/xt_geoip_build -D /usr/share/xt_geoip *.csv

echo "Now configure IPTables with something like this to block China (CN), Ukraine (UA), Taiwan (TW):"
echo "iptables -A INPUT -m geoip --src-cc CN,UA,TW -j DROP"
echo ""
echo "This would block all but US and a few others (US, Great Britain, Canada, Germany):"
echo "iptables -P INPUT DROP"
echo "iptables -A INPUT -s 192.168.0.0/16 -j ACCEPT"
echo "iptables -A INPUT -s 172.22.0.0/12 -j ACCEPT"
echo "iptables -A INPUT -s 10.0.0.0/8 -j ACCEPT"
echo "iptables -A INPUT -s 127.0.0.0/8 -j ACCEPT"
echo "iptables -A INPUT -s 224.0.0.0/4 -j ACCEPT"
echo "iptables -A INPUT -d 224.0.0.0/4 -j ACCEPT"
echo "iptables -A INPUT -s 240.0.0.0/5 -j ACCEPT"
echo "iptables -A INPUT -d 240.0.0.0/5 -j ACCEPT"
echo "iptables -A INPUT -d 239.255.255.0/24 -j ACCEPT"
echo "iptables -A INPUT -d 255.255.255.255  -j ACCEPT"
echo "iptables -A INPUT -m geoip --src-cc US,GB,CA,DE -j ACCEPT"
echo ""
echo "Note: You can add max 10 countries / rule"
echo ""
echo "Help:"
echo "iptables -m geoip --help"

