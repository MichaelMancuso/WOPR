#!/bin/bash

sudo apt-get install libxml2-dev libxslt-dev python-dev python-matplotlib python-serial python-wxgtk3.0 python-wxtools python-lxml python-scipy python-opencv ccache gawk git python-pip python-pexpect python-dev python-opencv python-wxgtk3.0 python-pip python-matplotlib python-pygame python-lxml

sudo pip2 install future pymavlink MAVProxy

# Ardu pilot software

# SITL - Software in the loop (SITL)
# http://ardupilot.org/dev/docs/setting-up-sitl-on-linux.html#setting-up-sitl-on-linux
cd /opt
mkdir drone
cd drone

git clone git://github.com/ArduPilot/ardupilot.git
cd ardupilot
git submodule update --init --recursive

pybombs install gr-eventstream gr-burst gr-mapper



