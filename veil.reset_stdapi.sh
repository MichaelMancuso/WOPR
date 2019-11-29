#!/bin/bash

# cd /usr/share/metasploit-framework/lib/rex/post/meterpreter
cd /usr/share/metasploit-framework

FILES=`find . -type f -exec grep -H 'stdapi2_' {} \; | grep -Eo -e "^.*?\.rb:" -e "^.*?\.php:" -e "^.*?\.py:" | sed "s|:$||g" | sort -u`

for CURFILE in $FILES
do
	sed -i "s|stdapi2_|stdapi_|g" $CURFILE
done

cd /opt/metasploit

FILES=`find . -type f -exec grep -H 'stdapi2_' {} \; | grep -Eo -e "^.*?\.rb:" -e "^.*?\.php:" -e "^.*?\.py:" | sed "s|:$||g" | sort -u`
# FILES=`find . -type f -exec grep -H "stdapi_" {} \; | grep -Eio "^.*?\.rb" | sort -u`

for CURFILE in $FILES
do
	sed -i "s|stdapi2_|stdapi_|g" $CURFILE
done

# now also need to fix a series of core_ commands... but a bit more carefully
FILES=`grep -r -Po "'core2_.*?'" * | grep -Eo -e "^.*?\.rb:" -e "^.*?\.php:" -e "^.*?\.py:" | sed "s|:$||g" | sort -u`

for CURFILE in $FILES
do
	sed -i "s|core2_channel_|core_channel_|g" $CURFILE
	sed -i "s|core2_transport_|core_transport_|g" $CURFILE

	sed -i "s|core2_crypto_negotiate|core_crypto_negotiate|g" $CURFILE
	sed -i "s|core2_enumextcmd|core_enumextcmd|g" $CURFILE
	sed -i "s|core2_loadlib|core_loadlib|g" $CURFILE
	sed -i "s|core2_machine_id|core_machine_id|g" $CURFILE
	sed -i "s|core2_uuid|core_uuid|g" $CURFILE
done

