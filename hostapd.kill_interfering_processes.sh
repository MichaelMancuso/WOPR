#!/bin/bash

# This script identifies any processes which might interfere with wireless
# tools such as airmon-ng and hostapd and kills them.
# Usual culprits: network-monitor, wicd, wpa_cli, wpa_supplicant, dhclient

airmon-ng check kill
