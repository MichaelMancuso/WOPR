#!/bin/bash

cd /usr/share/xt_geoip
/usr/lib/xtables-addons/xt_geoip_dl
/usr/lib/xtables-addons/xt_geoip_build -D /usr/share/xt_geoip *.csv

