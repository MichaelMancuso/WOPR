#!/bin/bash

# Note: This interface is more like OSX than LXDE

apt-get install xfce4 xfce4-cpugraph-plugin xfce4-battery-plugin
echo "Select XFCE from the following list..."
update-alternatives --config x-session-manager
