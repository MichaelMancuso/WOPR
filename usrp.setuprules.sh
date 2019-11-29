#!/bin/bash

echo "[`date`] Downloading UHD images..."
$HOME/gnuradio/lib/uhd/utils/uhd_images_downloader.py
echo "[`date`] Configuring udev rules.d..."
sudo cp $HOME/gnuradio/lib/uhd/utils/uhd-usrp.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
echo "[`date`] Done."

