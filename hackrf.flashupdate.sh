#!/bin/bash

# See https://github.com/mossmann/hackrf/wiki/Updating-Firmware for details

cd /opt/sdr/hackrf/hackrf
git pull

if [ $? -gt 0 ]; then
	echo "ERROR updating via git."
	exit 1
fi

cd /opt/sdr/hackrf/hackrf/firmware/hackrf_usb/build
hackrf_spiflash -w hackrf_one_usb.bin

read -p "Reboot the HackRF and press enter when done to update complex programmable logic device (CPLD):"

cd /opt/sdr/hackrf/hackrf/firmware/cpld
hackrf_cpldjtag -x firmware/cpld/sgpio_if/default.xsvf

