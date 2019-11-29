#!/bin/bash

if [ ! -e /opt/winetricks ]; then
	cd /opt
	mkdir winetricks
	cd winetricks
	wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
	chmod +x winetricks
	ln -s /opt/winetricks/winetricks /usr/bin/winetricks
fi

OLDWINEARCH=$WINEARCH

export WINEARCH="win32"

winetricks -q corefonts
winetricks -q dotnet45

export WINEARCH=$OLDWINEARCH

if [ ! -e $HOME/.wine/drive_c/Program Files/gbm ]; then
	mkdir $HOME/.wine/drive_c/Program Files/gbm/
fi

echo "[`date`] Prerequisites installed."
echo "[`date`] Copy files to ~/.wine/drive_c/Program Files/gbm."


