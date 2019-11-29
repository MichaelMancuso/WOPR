#/bin/sh

ShowUsage() {
	echo ""
	echo "$0 provides basic configuration of the BackTrack 4+ Ubuntu"
	echo "installation."
	echo ""
	echo "Options:"
	echo "--help      This Screen"
	echo "--wireless  Add wireless modules"
	echo ""
}

WIRELESS=0

for i in $*
do
	case $i in
	--wireless)
		WIRELESS=1
	;;
	*)
		ShowUsage
		exit 1
	;;
	esac
done

# Script to customize a fresh boot of a Backtrack cd...
echo "Checking for IP address..."
NUMADDR=`ifconfig | grep "inet addr" | grep -v "127\.0\.0\.1" | wc -l`

if [ $NUMADDR -eq 0 ]; then
	echo "No address found.  Requesting via dhcp..."
	dhclient eth0
else
	echo "Found address.  Continuing..."
fi

NUMADDR=`ifconfig | grep "inet addr" | grep -v "127\.0\.0\.1" | wc -l`
if [ $NUMADDR -eq 0 ]; then
	echo "Unable to find an IP address.  Check connectivity and try again."
	exit 1
fi

echo "Installing gedit..."
apt-get -y install gedit > /dev/null

echo "Copying scripts..."
cp -u * /usr/bin

echo "Updating metasploit..."
msfupdate

if [ $WIRELESS -eq 1 ]; then
	echo "Configuring wirleless tools..."
	cd /tmp
	svn co http://trac.aircrack-ng.org/svn/trunk/ aircrack-ng
	cd aircrack-ng
	make
	make install
	
	cd ..
	rm -rf aircrack-ng
	wget http://www.cdc.informatik.tu-darmstadt.de/aircrack-ptw/download/aircrack-ptw-1.0.0.tar.gz
	tar -zxvf aircrack-ptw-1.0.0.tar.gz
	cd aircrack-ptw-1.0.0
	make
	cp aircrack-ptw /usr/bin
	cd ..
	rm -rf aircrack-ptw-1.0.0

	./madwifi.sh install

	CURDIR=`pwd`

	cd /tmp
	
	$CURDIR/freeradius-wpe.install.sh
	$CURDIR/hostapd.install.sh

	cd $CURDIR

	if [ -d ../../../../../Junkyard/Network/SecurityScanners/Wireless/hostapd/etc_hostapd ]; then
		cp -u ../../../../../Junkyard/Network/SecurityScanners/Wireless/hostapd/etc_hostapd/* /etc/hostapd
	fi

	$CURDIR/berry4all_install.sh

	if [ -e ../../BBTether/.bbtether.conf ]; then
		cp ../../BBTether/.bbtether.conf ~
	fi

fi

# Needed for karmetasploit...
gem install activerecord sqlite3-ruby
cd /opt/metasploit3/msf3
wget http://metasploit.com/users/hdm/tools/karma.rc

echo "Done."

