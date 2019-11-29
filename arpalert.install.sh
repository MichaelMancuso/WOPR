#!/bin/bash

echo "[`date`] Installing arpalert from configured repositories..."
apt-get install arpalert
update-rc.d -f arpalert remove
echo "[`date`] Configuring smtp-cli for email alerting..."
apt-get -y install libio-socket-ssl-perl libdigest-hmac-perl libterm-readkey-perl libmime-lite-perl libfile-type-perl libio-socket-inet6-perl

if [ ! -e /usr/bin/smtp-cli ]; then
	if [ -e smtp-cli ]; then
		cp smtp-cli /usr/bin
		chmod +x /usr/bin/smtp-cli
	else
		echo "/usr/bin/smtp-cli not found.  Downloading smtp-cli..."
		cd /tmp
		wget -O smtp-cli http://www.logix.cz/michal/devel/smtp-cli/smtp-cli 2>/dev/null

		if [ -e smtp-cli ]; then
			sudo cp smtp-cli /usr/bin
			sudo chmod +x /usr/bin/smtp-cli
		else
			echo "ERROR: Unable to download smtp-cli.  Manually download and/or copy to /usr/bin"
		fi
	fi
fi

echo "[`date`] Configuring arp-scan..."
apt-get -y install arp-scan

if [ -e arp.ip_mac_address_mapper.sh ]; then
	cp arp.ip_mac_address_mapper.sh /usr/bin
	chmod +x /usr/bin/arp.ip_mac_address_mapper.sh
fi

echo "[`date`] Configuring perl Net::Syslog module for syslog..."
cpan -i Net::Syslog

echo "[`date`] Copying baseline config and alert script to /etc/arpalert..."
if [ -e arpalert.conf ]; then
	cp arpalert.conf /etc/arpalert/
else
	echo "ERROR: Unable to find ./arpalert.conf"
fi

if [ -e arpalert.notify.sh ]; then
	cp arpalert.notify.sh /etc/arpalert/
	chmod +x /etc/arpalert/arpalert.notify.sh
else
	echo "ERROR: Unable to find ./arpalert.notify.sh"
fi

touch /etc/arpalert/valid_network_ranges.txt

if [ -e syslog.send.pl ]; then
	cp syslog.send.pl /usr/bin/
	chmod +x /usr/bin/syslog.send.pl
else
	echo "ERROR: Unable to find ./syslog.send.pl"
fi

if [ -e ip.expandprefix.sh ]; then
	cp ip.expandprefix.sh /usr/bin/
	chmod +x /usr/bin/ip.expandprefix.sh
else
	echo "ERROR: Unable to find ./ip.expandprefix.sh"
fi

if [ -e timeout ]; then
	cp timeout /usr/bin/
	chmod +x /usr/bin/timeout
else
	echo "ERROR: Unable to find ./timeout"
fi

if [ -e arpalert.logrotate ]; then
	if [ -e /etc/logrotate.d ]; then
		cp arpalert.logrotate /etc/logrotate.d/arpalert
	fi
fi

echo "[`date`] Setting initial file configs..."

echo "" > /etc/arpalert/authrq.conf
echo "# <Mac Address>	<IP>	<Interface>" > /etc/arpalert/maclist.allow

echo ""
echo "[`date`] Finished.  Next Steps: Use one or more of the following techniques to build a valid /etc/arpalert/mac.allow file:"
echo "1. Dump DHCP leases from DHCP server"
echo "2. Use the arp.ip_mac_address_mapper.sh script to scan subnets"
echo "3. Allow arpalert to build a /var/lib/arpalert/arpalert.leases file then copy that to /etc/arpalert/mac.allow"
echo ""
echo "Also in the initial arpalert.conf file, alerts for mac address changes are disabled.  You may want to enable that module, however it could require some tuning and alert script adjustment to make sure it is appropriately detected and alerted."
echo ""
echo "When ready, add arpalert to auto-start with:"
echo "update-rc.d arpalert defaults"
echo "/etc/init.d/arpalert restart"
echo ""
echo "[`date`] Done."
echo ""
