#!/bin/bash

if [ -e /cygdrive/c/Tools/Meterpreter-source/source ]; then
	cd /cygdrive/c/Tools/Meterpreter-source/source

	sed -i "s|stdapi_|stdapi2_|g" extensions/stdapi/server/general.c
	sed -i "s|stdapi_|stdapi2_|g" extensions/stdapi/server/stdapi.c

	# now also need to fix a series of core_ commands... but a bit more carefully
	FILES=`grep -r -Po "core_.*?" * | grep -Eo -e "^.*?\.c:" -e "^.*?\.h:" | sed "s|:$||g" | sort -u`

	for CURFILE in $FILES
	do
		sed -i "s|core_channel_|core2_channel_|g" $CURFILE
		sed -i "s|core_transport_|core2_transport_|g" $CURFILE

		sed -i "s|core_crypto_negotiate|core2_crypto_negotiate|g" $CURFILE
		sed -i "s|core_enumextcmd|core2_enumextcmd|g" $CURFILE
		sed -i "s|core_loadlib|core2_loadlib|g" $CURFILE
		sed -i "s|core_machine_id|core2_machine_id|g" $CURFILE
		sed -i "s|core_uuid|core2_uuid|g" $CURFILE
	done
else
	echo "ERROR: Unable to find directory"
fi

