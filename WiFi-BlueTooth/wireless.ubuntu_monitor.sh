#!/bin/bash
INTERFACE="wlx00c0ca71cc29"

ifconfig $INTERFACE down
iwconfig $INTERFACE mode monitor
ifconfig $INTERFACE up

