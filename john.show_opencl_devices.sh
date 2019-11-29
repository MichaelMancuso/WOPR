#!/bin/bash

if [ -e /opt/john/1.8-MultiCore ]; then
	cd /opt/john/1.8-MultiCore

	./john --list=opencl-devices
else
	john --list=opencl-devices
fi
