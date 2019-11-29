#!/bin/bash

iptables -F INPUT
iptables -P INPUT DROP
iptables -A INPUT -s 192.168.0.0/16 -j ACCEPT
iptables -A INPUT -s 172.22.0.0/12 -j ACCEPT
iptables -A INPUT -s 10.0.0.0/8 -j ACCEPT
iptables -A INPUT -s 127.0.0.0/8 -j ACCEPT
iptables -A INPUT -s 224.0.0.0/4 -j ACCEPT
iptables -A INPUT -d 224.0.0.0/4 -j ACCEPT
iptables -A INPUT -s 240.0.0.0/5 -j ACCEPT
iptables -A INPUT -d 240.0.0.0/5 -j ACCEPT
iptables -A INPUT -d 239.255.255.0/24 -j ACCEPT
iptables -A INPUT -d 255.255.255.255  -j ACCEPT
iptables -A INPUT -m geoip --src-cc US,GB,CA,DE -j ACCEPT

