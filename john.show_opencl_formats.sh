#!/bin/bash

if [ -e /opt/john/1.8-MultiCore ]; then
	cd /opt/john/1.8-MultiCore

	./john --list=formats | tr ' ' '\n' | grep -v "^$" | sed "s|,||g" | sort -u | grep opencl
else
	john --list=formats  | tr ' ' '\n' | grep -v "^$" | sed "s|,||g" | sort -u | grep opencl
fi
