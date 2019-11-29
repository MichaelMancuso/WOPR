#!/bin/bash

if [ -e /cygdrive/c/Tools/Meterpreter-source/source ]; then
	cd /cygdrive/c/Tools/Meterpreter-source/source

	sed -i "s|stdapi2_|stdapi_|g" extensions/stdapi/server/general.c
	sed -i "s|stdapi2_|stdapi_|g" extensions/stdapi/server/stdapi.c

	# now also need to fix a series of core_ commands... but a bit more carefully
	FILES=`grep -r -Po "core2_.*?" * | grep -Eo -e "^.*?\.c:" -e "^.*?\.h:" | sed "s|:$||g" | sort -u`

	for CURFILE in $FILES
	do
		sed -i "s|core2_|core_|g" $CURFILE
	done
else
	echo "ERROR: Unable to find directory"
fi

