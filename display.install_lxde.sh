#!/bin/bash

apt-get install lxde-core lxde kali-defaults kali-root-login desktop-base
echo "Select LXDE from the following list..."
update-alternatives --config x-session-manager
