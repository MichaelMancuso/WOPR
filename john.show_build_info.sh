#!/bin/bash

if [ -e /opt/john/1.8-MultiCore ]; then
	cd /opt/john/1.8-MultiCore

	./john --list=build-info
else
	john --list=build-info
fi
