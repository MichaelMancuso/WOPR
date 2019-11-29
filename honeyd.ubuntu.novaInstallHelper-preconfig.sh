#!/bin/bash
# If VMWare EasyInstall gets stuck for Ubuntu, undo with this.
# sudo mv /etc/issue.backup /etc/issue
# mv /etc/rc.local.backup /etc/rc.local
# mv /opt/vmware-tools-installer/lightdm.conf /etc/init

# If you install Ubuntu server, you can add the GUI with this:
# apt-get install ubuntu-desktop

echo "[`date`] Preconfiguring system for Nova/honeyd installation..."

INSTALLVMWARE=0

apt-get -y install aptitude gedit nmap npm 
if [ $INSTALLVMWARE -eq 1 ]; then
	echo "[`date`] Setting up VMWare prerequisites..."
	apt-get -y install build-essential linux-headers-$(uname -r)
	
	if [ ! -e /usr/src/linux-headers-$(uname -r)/include/linux/version.h ]; then
		cd /usr/src/linux-headers-$(uname -r)/include/linux
		ln -s /usr/src/linux-headers-$(uname -r)/include/generated/uapi/linux/version.h /usr/src/linux-headers-$(uname -r)/include/linux/version.h
	fi
fi

# Need this for nova helper npm cert error that prevents honeyd / nova install
npm config set strict-ssl false

echo "[`date`] Done.  Run novaInstallHelper.sh to install honeyd 1.6d and the Nova interface."