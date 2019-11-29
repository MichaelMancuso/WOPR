#!/bin/bash

USERNAME=`whoami`

echo -n "What is your username on the Alienvault server? [$USERNAME]: "
read -e USERNAME_RESPONSE

if [ ${#USERNAME_RESPONSE} -gt 0 ]; then
	USERNAME=$USERNAME_RESPONSE
fi

ssh $USERNAME@172.22.200.10 ossim-get-events_per_day.sh
