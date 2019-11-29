#!/bin/sh
# Install the required bbteather / berry4all pre-requisites

echo "Installing prerequisites..."
sudo apt-get -y install python libusb-dev ppp python-usb python-wxgtk2.8

echo "Retrieving latest version from svn repository..."
svn checkout http://svn.colar.net/bbtether/src/bbtether bbteather

mv bbteather /usr/local/share
CURDIR=`pwd`
cd /usr/local/share/bbteather
cp berry4all.sh berry4all.sh.bak
echo '#!/bin/sh' > berry4all.sh
echo 'CURDIR=`pwd`' >> berry4all.sh
echo 'cd /usr/local/share/bbteather' >> berry4all.sh

echo 'if [ "$(id -u)" != "0" ]; then' >> berry4all.sh
echo '	sudo python bbgui.py' >> berry4all.sh
echo 'else' >> berry4all.sh
echo '	python bbgui.py' >> berry4all.sh
echo 'fi'  >> berry4all.sh
echo 'cd $CURDIR'  >> berry4all.sh

echo "run berry4all to start client."

ln -s /usr/local/share/bbteather/berry4all.sh /usr/bin/berry4all

cd $CURDIR
