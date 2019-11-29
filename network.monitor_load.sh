#!/bin/bash

which nload > /dev/null 

if [ $? -gt 0 ]; then
	apt-get -y install nload
fi

nload
