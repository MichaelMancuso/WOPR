#!/bin/bash
FILELIST=`ls Telnet*.txt`

for CURFILE in $FILELIST
do
	CURID=`echo "$CURFILE" | grep -Eio "\-[0-9]{4,4}\.txt" | sed "s|\-||g" | sed "s|\.txt||g"`
	convert.as400-telnet_to_ASCII.sh $CURFILE telnet-$CURID.txt
done

