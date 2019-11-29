#!/bin/bash

sudo airmon-ng start wlp2s0
sudo kismet_server -n -X -–daemonize -c wlp2s0mon 2>&1 > /dev/null &
sudo airodump-ng --band ag wlp2s0mon

