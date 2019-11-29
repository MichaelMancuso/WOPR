#!/bin/bash -x

# cd /usr/share/metasploit-framework/lib/rex/post/meterpreter
cd /usr/share/metasploit-framework/

FILES=`find . -type f -exec grep -H 'stdapi_' {} \; | grep -Eo -e "^.*?\.rb:" -e "^.*?\.php:" -e "^.*?\.py:" | sed "s|:$||g" | sort -u`
# FILES=`find . -type f -exec grep -H "stdapi_" {} \; | grep -Eio "^.*?\.rb" | sort -u`

for CURFILE in $FILES
do
	sed -i "s|stdapi_|stdapi2_|g" $CURFILE
done

cd /opt/metasploit

FILES=`find . -type f -exec grep -H 'stdapi_' {} \; | grep -Eo -e "^.*?\.rb:" -e "^.*?\.php:" -e "^.*?\.py:" | sed "s|:$||g" | sort -u`

for CURFILE in $FILES
do
	sed -i "s|stdapi_|stdapi2_|g" $CURFILE
done

# now also need to fix a series of core_ commands... but a bit more carefully
FILES=`grep -r -Po "'core_.*?'" * | grep -Eo -e "^.*?\.rb:" -e "^.*?\.php:" -e "^.*?\.py:" | sed "s|:$||g" | sort -u`

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

