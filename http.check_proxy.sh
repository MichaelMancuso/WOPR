#!/bin/bash

dns.check_wpad.sh

if [ $? -gt 0 ]; then
	exit 1
fi

