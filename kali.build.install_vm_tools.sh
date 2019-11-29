#!/bin/bash

echo "Installing open-vm tools..."
apt-get install open-vm-tools
apt-get install open-vm-toolbox
echo "Restarting system..."
shutdown -r now


