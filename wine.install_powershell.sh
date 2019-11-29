#!/bin/bash

# Setting a 32-bit wine prefix:
if [ ! -e $HOME/.wine64 ]; then
	mv $HOME/.wine $HOME/.wine64
	WINEARCH=win32 WINEPREFIX=$HOME/.wine winecfg
fi

apt-get -y install winetricks winbind
#cd $HOME/Downloads
#wget  https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
#chmod +x winetricks
winetricks corefonts
winetricks wmi
winetricks -q msxml3 dotnet35sp1
winetricks lucida
winetricks windowscodecs
wget -O $HOME/.cache/winetricks/WindowsXP-KB968930-x86-ENG.exe http://download.microsoft.com/download/E/C/E/ECE99583-2003-455D-B681-68DB610B44A4/WindowsXP-KB968930-x86-ENG.exe
wine $HOME/.cache/winetricks/WindowsXP-KB968930-x86-ENG.exe

