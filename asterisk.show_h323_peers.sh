#!/bin/bash

# Use "core show channeltypes" and "module show like ooh" to verify ooh323 is running
# It may not work if there's no /etc/asterisk/ooh323.conf

# Sample working ooh323.conf
# [general]
# port=1720
# bindaddr=0.0.0.0
# faststart=yes
# h245tunneling=yes
# gatekeeper=DISABLE
#
# [<peer ip>]
# type=friend
# context=outbound
# ip=<ip>
# port=1720
# disallow=all
# allow=ulaw
# canreinvite=no

asterisk -rx "ooh323 show peers"
