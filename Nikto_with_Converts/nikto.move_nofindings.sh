#!/bin/sh

# This file will look for Nikto result files in the current directory
# that have a wc -l of 15 indicating no additional findings.

DIRLISTING=`ls -1 *.nikto.txt`
FILESMOVED=0
FILESMOVED_MS=0

for CURFILE in $DIRLISTING
do
	if [ -e $CURFILE ]; then
		# Check std files
		CURLINES=`cat $CURFILE | grep -v "^- Root page \/ redirects to" | grep -v "Allowed HTTP Methods:" | \
					grep -v "Public HTTP Methods" | grep -v "Retrieved X-Powered-By header" | wc -l`

		CURLINES_MS=`cat $CURFILE | grep -v "^- Root page \/ redirects to" | grep -v "Allowed HTTP Methods:" | \
					grep -v "Public HTTP Methods" | grep -v "Retrieved X-Powered-By header" | \
					grep -v "Microsoft-IIS.* appears to be outdated" | wc -l`

		if [ $CURLINES -le 15 ]; then

			if [ ! -d nofindings ]; then
				mkdir nofindings
			fi

			mv $CURFILE nofindings

			FILESMOVED=$(( FILESMOVED + 1 ))
		else
			if [ $CURLINES_MS -le 15 ]; then
				if [ ! -d only_outdated_iis ]; then
					mkdir only_outdated_iis
				fi

				mv $CURFILE only_outdated_iis
				FILESMOVED_MS=$(( FILESMOVED_MS + 1 ))
			fi
		fi

		# Check SSL files

		if [ -e $CURFILE ]; then
			# Not already moved.
			cat $CURFILE | grep -i "nikto\.pl.*-ssl" > /dev/null

			if [ $? -eq 0 ]; then
				CURLINES=`cat $CURFILE | grep -v "^- Root page \/ redirects to" | grep -v "Allowed HTTP Methods:" | \
						grep -v "Public HTTP Methods" | grep -v "Retrieved X-Powered-By header" | wc -l`

				CURLINES_MS=`cat $CURFILE | grep -v "^- Root page \/ redirects to" | grep -v "Allowed HTTP Methods:" | \
						grep -v "Public HTTP Methods" | grep -v "Retrieved X-Powered-By header" | \
						grep -v "Microsoft-IIS.* appears to be outdated" | wc -l`
				# This is an SSL file and need to do -le 20
				if [ $CURLINES -le 20 ]; then
					mv $CURFILE nofindings

					FILESMOVED=$(( FILESMOVED + 1 ))
				else
					if [ $CURLINES_MS -le 20 ]; then
						mv $CURFILE only_outdated_iis
						FILESMOVED_MS=$(( FILESMOVED_MS + 1 ))
					fi
				fi

			fi
		fi
	fi
done

echo "$FILESMOVED regular files moved."
echo "$FILESMOVED IIS outdated only files moved."

