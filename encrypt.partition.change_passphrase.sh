#!/bin/bash

echo "cryptsetup luksChangeKey <target partition> -S <target key slot number>"
echo "Where slot numbers start at 0.  Luks can store up to 8 keys."
echo ""
echo "Example: cryptsetup luksChangeKey /dev/sdb1 -S 0"
echo ""
echo "Keys can also be added or removed using:"
echo "cryptsetup -y luksAddKey <target partition>"
echo "cryptsetup luksRemoveKey <target partition>"
echo ""

