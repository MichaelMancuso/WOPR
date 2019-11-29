#!/bin/bash
# hostapd-wpe build file

tar -zxf hostapd-2.2.tar.gz
cd hostapd-2.2
patch -p1 < ../hostapd-wpe.patch 
cd hostapd
make
