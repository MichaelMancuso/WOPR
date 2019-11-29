#!/bin/bash

rm -rf /var/lib/apt/lists
apt-get update 
apt-get -y install kali-archive-keyring
apt-get update
