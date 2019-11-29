#!/bin/bash

ShowUsage() {
	echo "Usage: $0 [--help] [--risk-name] [--cache] [single nikto file]"
	echo "$0 will take either the specified nikto output file or "
	echo "all *.nikto.txt files in the current directory and "
	echo "convert them to CSV format with the following columns:"
	echo "Hostname, Host IP, Port, Vuln Id (OSVDB), Risk Level, Vulnerability, Observation, Remediation"
	echo ""
	echo "--risk-name  By default output will be 1-5 for risk levels"
	echo "             --risk-name will output High, Medium, etc. instead of the number."
	echo "--nocache      Do not Use local cache files to prime / save OSVDB lookups."
}

# This file will convert all Nikto findings to a single CSV

# 0 for number, 1 for name
RISKDISPLAY=0
LISTINGFILTER="*.nikto.txt"
USECACHE=1

for i in $*
do
	case $i in
	--help)
		ShowUsage
		exit 1
	;;
	--risk-name)
		RISKDISPLAY=1
	;;
	--nocache)
		USECACHE=0
	;;
	*)
		LISTINGFILTER=$i
	;;
	esac
done

DIRLISTING=`ls -1 $LISTINGFILTER`
NUMFILES=`echo "$DIRLISTING" | grep -v "^$" | wc -l`

FILESPROCESSED=0

IFS_BAK=$IFS
IFS="
"
OSVDBList=""
OSVDBDescription=""
OSVDBSolution=""
CACHEDIR=`echo "$HOME/tmp"`

if [ $USECACHE -eq 1 ]; then
	if [ -d /opt/osvdb ]; then
		CACHEDIR="/opt/osvdb"
	else

		if [ ! -d $CACHEDIR ]; then
			mkdir $CACHEDIR
		fi
	fi

	CACHE_RISK=`echo "$CACHEDIR/osvdb.risk.cache"`
	CACHE_DESCRIPTION=`echo "$CACHEDIR/osvdb.description.cache"`
	CACHE_SOLUTION=`echo "$CACHEDIR/osvdb.solution.cache"`

	if [ -e $CACHE_RISK ]; then
		echo "Reading risk cache..." 1>&2
		OSVDBList=`cat $CACHE_RISK`
	fi

	if [ -e $CACHE_DESCRIPTION ]; then
		echo "Reading description cache..." 1>&2
		OSVDBDescription=`cat $CACHE_DESCRIPTION`
	fi

	if [ -e $CACHE_SOLUTION ]; then
		echo "Reading solution cache..." 1>&2
		OSVDBSolution=`cat $CACHE_SOLUTION`
	fi
fi

echo "[`date`] Processing $NUMFILES files..." >&2

echo "\"HOSTNAME\",\"HOST IP\",\"PORT\",\"VULN ID\",\"RISK LEVEL\",\"VULNERABILITY\",\"OBSERVATION\",\"Remediation\""

for CURFILE in $DIRLISTING
do
	ISSUMMARY=`echo "$CURFILE" | grep "summary.nikto.txt" | wc -l`

	if [ -e $CURFILE -a $ISSUMMARY -eq 0 ]; then

		FILESPROCESSED=$(( FILESPROCESSED + 1 ))

		echo "[`date`] Processing $CURFILE ($FILESPROCESSED/$NUMFILES)..." >&2

		cat $CURFILE | grep -E "+ No web server found on" > /dev/null

		if [ $? -gt 0 ]; then
			HOSTNAME=""
			TARGETPORT=""
			TARGETIP=""

			TARGETIP=`cat $CURFILE | grep "+ Target IP:" | head -1 | grep -Eio "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
			HOSTNAME=`cat $CURFILE | grep "+ Target Hostname:" | head -1 | sed "s|+ Target Hostname:\s||" | sed "s| ||g"`
			TARGETPORT=`cat $CURFILE | grep "+ Target Port:" | head -1 | grep -Eio "[0-9]{1,5}"`

			# Get line of "Server:"
			SERVERLINE=`cat $CURFILE | grep -n "+ Server:" | grep -Eio "^[0-9]{1,2}" | head -1`
	
			PARAM=`echo "$SERVERLINE d" | sed "s| ||"`
			VULNS=`cat $CURFILE | sed "/$PARAM/d" | grep -Eiv "[0-9]{1,5} items checked" | grep -v -e "+ End Time" -e "^--" -e "host(s) tested" -e "+ Target IP" -e "+ Target Hostname" -e "+ Target Port" -e "+ Server:" -e "End Time" -e "+ SSL Info"`
			VULNS=`echo "$VULNS" | grep -v -e "+ Using Encoding" -e "+ Start Time" -e "- Nikto " -e " Issuer:" -e " Ciphers:" -e "Virtual Host:"`
			# Remove all lines that don't begin with a + or a -
			VULNS=`echo "$VULNS" | grep -e "^+" -e "^-"`
			VULNS=`echo "$VULNS" | sed "s|^+ ||g" | sed "s|^- ||g" | grep -v "No CGI Directories found" | sed "s|\"|\'|g"`

			# Find OSVDB Values

			for CURVULN in $VULNS
			do
				echo "$CURVULN" | grep "^OSVDB" > /dev/null

				if [ $? -eq 0 ]; then
					# Found OSVDB
					OSVDB=`echo "$CURVULN" | grep -Pio "OSVDB-[0-9]{1,6}" | head -1`

					# See if it's in our list...
					echo "$OSVDBList" | grep "$OSVDB:" > /dev/null

					if [ $? -gt 0 ]; then
						# Not in our list
						CVSSSCORE=""
					
						OSVDBID=`echo "$OSVDB" | sed "s|OSVDB-||"`
	
						echo "Checking risk level for $OSVDB" 1>&2
	#					echo "DEBUG: $OSVDBList" 1>&2
	
						OSVDBPAGE=`wget -O - -U "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.1.9) Gecko/20100315 Firefox/3.5.9 ( .NET CLR 3.5.30729)" http://osvdb.org/show/osvdb/$OSVDBID 2>/dev/null`
						CVSSSCORE=`echo "$OSVDBPAGE" | grep -Pio "CVSSv2 Base Score = [0-9]{1,2}\.[0-9]{1,2}" | grep -Pio "[0-9]{1,2}\.[0-9]{1,2}"`
						DESCR=`echo "$OSVDBPAGE" | tr '\n' ' ' | tr '\r' ' ' | sed "s|.*Description<\/h1><\/td>||" | sed "s|<\/td>.*||" | perl -pe "s|^.*?>||" | sed "s|  ||g" | sed "s|  ||g" | sed "s|^ ||"`	

						echo "$OSVDBPAGE" | tr '\n' ' ' | tr '\r' ' ' | grep -E "Solution<\/h1><\/td>" > /dev/null

						if [ $? -eq 0 ]; then
							SOL=`echo "$OSVDBPAGE" | tr '\n' ' ' | tr '\r' ' ' | sed "s|.*Solution<\/h1><\/td>||" | sed "s|<\/td>.*||" | perl -pe "s|^.*?>||" | sed "s|  ||g" | sed "s|  ||g" | sed "s|^ ||"`	
						else
							SOL=""
						fi

						if [ ${#CVSSSCORE} -gt 0 ]; then
							PRIMARYSCORE=`echo "$CVSSSCORE" | sed "s|\..*||"`
					
							# Vulnerabilities are labeled Low severity if they have a CVSS base score of 0.0-3.9.
							# Vulnerabilities will be labeled Medium severity if they have a base CVSS score of 4.0-6.9.
							# Vulnerabilities will be labeled High severity if they have a CVSS base score of 7.0-10.0.
	
							if [ ${#PRIMARYSCORE} -gt 0 ]; then					
								if [ $PRIMARYSCORE -lt 4 ]; then
									OSVDBList=`echo -e "$OSVDBList\\n$OSVDB:Low" | sed "s|\"||g"`
								else
									if [ $PRIMARYSCORE -lt 7 ]; then
										OSVDBList=`echo -e "$OSVDBList\\n$OSVDB:Medium" | sed "s|\"||g"`
									else
										OSVDBList=`echo -e "$OSVDBList\\n$OSVDB:High" | sed "s|\"||g"`
									fi
								fi
							fi
						else
							# No CVSS Score for this OSVDB Id
							OSVDBList=`echo -e "$OSVDBList\\n$OSVDB:Unknown" | sed "s|\"||g"`
						fi

						OSVDBDescription=`echo -e "$OSVDBDescription\\n$OSVDB:$DESCR" | sed "s|\"||g" | sed "s|<em style='font-weight:bold;'>.||g" | sed "s|)<\/em> ||g" | sed "s|<a href=||g" | sed "s|<\/a>||g" | sed "s|<br\/>||g" | perl -pe "s|target=.*?>||"`
						OSVDBSolution=`echo -e "$OSVDBSolution\\n$OSVDB:$SOL" | sed "s|\"||g" | sed "s|<em style='font-weight:bold;'>.||g" | sed "s|)<\/em> ||g" | sed "s|<a href=||g" | sed "s|<\/a>||g" | sed "s|<br\/>||g" | perl -pe "s|target=.*?>||"`
					fi
				fi
			done

			for CURVULN in $VULNS
			do
				echo "$CURVULN" | grep "^OSVDB" > /dev/null

				if [ $? -eq 0 ]; then
					# Found OSVDB
					# Replace : after OSVDB with a ,
					OSVDB=`echo "$CURVULN" | grep -Pio "OSVDB-[0-9]{1,6}" | head -1`

					# Note: Need to use 'perl -pe' below rather than sed because
					# sed didn't recognize non-greedy .*? etc.  This perl syntax does!
					NEWVULN=`echo "$CURVULN" | perl -pe 's|^OSVDB-[0-9]{1,6}\: ||'`

					# Find risk level

					RISKLEVEL=`echo "$OSVDBList" | grep "$OSVDB:" | grep -Eo -e "Low" -e "Medium" -e "High"`

					if [ $RISKDISPLAY -eq 0 ]; then
						# Convert to number
						case $RISKLEVEL in
						Low)
							NUMRISK=2
						;;
						Medium)
							NUMRISK=3
						;;
						High)
							NUMRISK=4
						;;
						*)
							NUMRISK=""
						;;
						esac
	
						RISKLEVEL=$NUMRISK
					fi

					DESCR=`echo "$OSVDBDescription" | grep "$OSVDB:" | sed "s|$OSVDB:||"`
					SOL=`echo "$OSVDBSolution" | grep "$OSVDB:" | sed "s|$OSVDB:||"`
					if [ ${#RISKLEVEL} -gt 0 ]; then
						# HOSTNAME, IP, PORT, OSVDB, Risk Level, Vuln
						echo "\"$HOSTNAME\",\"$TARGETIP\",\"$TARGETPORT\",\"$OSVDB\",\"$RISKLEVEL\",\"$NEWVULN\",\"$DESCR\",\"$SOL\""
					else
						if [ $RISKDISPLAY -eq 0 ]; then
							RISKLEVEL=-1
						else
							RISKLEVEL="Unrated"
						fi

						# HOSTNAME, IP, PORT, OSVDB, <space for risk>, Vuln
						echo "\"$HOSTNAME\",\"$TARGETIP\",\"$TARGETPORT\",\"$OSVDB\",\"$RISKLEVEL\",\"$NEWVULN\""
					fi
				else
					echo "$CURVULN" | grep -i -e "ETag header found on server" -e "Retrieved X-Powered-By header" \
						-e "Retrieved x-aspnet-version header" -e "HTTP method ('Public' Header): 'PROPPATCH' indicates WebDAV is installed" \
						-e "HTTP method ('Allow' Header): 'PROPPATCH' indicates WebDAV is installed." \
						-e "Allowed HTTP Methods: OPTIONS, TRACE, GET, HEAD, POST" -e "Public HTTP Methods: OPTIONS, TRACE, GET, HEAD, POST" \
						-e "Microsoft-IIS/6.0 appears to be outdated (4.0 for NT 4, 5.0 for Win2k, current is at least 7.0)" > /dev/null

					if [ $? -eq 0 ]; then
						# Found one of the patterns above.  Risks are Informational
						# HOSTNAME, IP, PORT, <blank OSVDB>, Risk Level, Vuln
						if [ $RISKDISPLAY -eq 0 ]; then
							RISKLEVEL=1
						else
							RISKLEVEL="Informational"
						fi

						echo "\"$HOSTNAME\",\"$TARGETIP\",\"$TARGETPORT\",\"\",\"$RISKLEVEL\",\"$CURVULN\""
					else

						echo "$CURVULN" | grep -i -e "FrontPage file found. This may contain useful information." > /dev/null


						if [ $? -eq 0 ]; then
							# Found one of the patterns above.  Risks are Low
							if [ $RISKDISPLAY -eq 0 ]; then
								RISKLEVEL=1
							else
								RISKLEVEL="Low"
							fi

							# HOSTNAME, IP, PORT, <blank OSVDB>, Risk Level, Vuln
							echo "\"$HOSTNAME\",\"$TARGETIP\",\"$TARGETPORT\",\"\",\"$LOW\",\"$CURVULN\""
						else
							if [ $RISKDISPLAY -eq 0 ]; then
								RISKLEVEL=-1
							else
								RISKLEVEL="Unrated"
							fi

							# HOSTNAME, IP, PORT, Risk Level, <blank OSVDB>, Vuln
							echo "\"$HOSTNAME\",\"$TARGETIP\",\"$TARGETPORT\",\"\",\"$RISKLEVEL\",\"$CURVULN\""
						fi
					fi
				fi
			done
		fi
	fi
done

if [ $USECACHE -eq 1 ]; then
	echo "Updating cache..." 1>&2

	echo "$OSVDBList" | sort -u | grep -Ev "^$"  | grep -v "^-e" > $CACHE_RISK
	echo "$OSVDBDescription" | sort -u | grep -Ev "^$"  | grep -v "^-e" > $CACHE_DESCRIPTION
	echo "$OSVDBSolution" | sort -u | grep -Ev "^$" | grep -v "^-e" > $CACHE_SOLUTION
fi

IFS=$IFS_BAK
IFS_BAK=

echo "" 1>&2
echo "Done" 1>&2
