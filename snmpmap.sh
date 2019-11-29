#!/bin/bash

# -----------------------------------------------------------------------------
# snmpmap
# 
# Written by Michael Piscopo
#
# -----------------------------------------------------------------------------

# --------------- Functions --------------------------
PrintTabs() {
#	echo -e "\n$1" | sed "s|.*?\n||"
	echo -e "$1" | sed "s|^-e ||"
}

# --------------- Main --------------------------

EXPECTED_ARGS=1
DEBUG=0

if [ $# -lt $EXPECTED_ARGS ]
then
  echo "usage: $0 <target ip address> [input file]"
  echo "$0 will try both SNMP v1 and SNMP v2 queries for each community in the"
  echo "specified file against the target system."
  echo "If metasploit is available, it will use the snmp scanner module,"
  echo "if not, it will use other snmp tools for the query (this will be slower)"
  exit 1
fi

if [ $# -gt 1 ]; then
	INPUTFILE=$2
else
	INPUTFILE="/opt/snmpmap/SnmpStrings.txt"
fi

if [ ! -e $INPUTFILE ] 
then
	if [ -e /opt/dnsmap/$INPUTFILE ] 
	then
		INPUTFILE=`echo /opt/dnsmap/$INPUTFILE`
	else
	  echo "File $INPUTFILE and /opt/dnsmap/$INPUTFILE does not exist.  Please check file location."
	  exit 1
	fi
fi

TARGET=$1

METASPLOIT=0

echo "[`date`] Starting SNMP mapping of $TARGET using file $INPUTFILE..."
NUMFOUND=0
TESTCOUNT=0

if [ $METASPLOIT -eq 1 ]; then
	SCANRESULT=`nmap -sU -p 161 --script=snmp-brute --script-args=snmp-brute.communitiesdb=$INPUTFILE $TARGET 2>&1`
	SCANIP=`echo "$SCANRESULT" | grep -Eio "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
	FOUNDSTRING=`echo "$SCANRESULT" | grep "^|_" | sed "s/^|_ //" | sed "s|^ ||" | sed "s| \- Valid credentials||"`

	echo ""
	if [ ${#FOUNDSTRING} -gt 0 ]; then
		echo "$SCANIP: $FOUNDSTRING"
	else
		echo "$SCANIP: No strings found."
	fi
	echo ""
	echo "[`date`] Finished mapping $TARGET."
else
	NAMELIST=`cat $INPUTFILE | grep -v "^$" | grep -v "#"`

	for line in $NAMELIST
	do
		# The Sed replace of \r is a safety check for files moving between
		# Windows an *nix.
		SNMPSTRING=`echo "$line" | sed "s|\r||"`

		TESTCOUNT=$(( TESTCOUNT + 1 ))

		FOUNDTYPE=0

		if [ $DEBUG -gt 0 ]; then
			echo "Testing $SNMPSTRING for Version 1"
		fi

		snmpwalk -r 0 -t 2 -v 1 -c $SNMPSTRING $TARGET system 2> /dev/null 1> /dev/null

	#	Get return code:
		CMDRESULT=`echo $?`

		if [ $DEBUG -gt 0 ]; then
			echo "Return code: $CMDRESULT"
		fi

		if [ $CMDRESULT -gt 0 ]; then
			if [ $DEBUG -gt 0 ]; then
				echo "Testing $SNMPSTRING for Version 2c"
			fi

			snmpwalk -r 0 -t 2 -v 2c -c $SNMPSTRING $TARGET system  2> /dev/null 1> /dev/null

			CMDRESULT2=`echo $?`

			if [ $CMDRESULT2 -gt 0 ]; then
				if [ $DEBUG -gt 0 ]; then
					echo "No response for $SNMPSTRING"
				fi
				FOUNDTYPE=0
			else
				if [ $DEBUG -gt 0 ]; then
					echo "Found Version 2c for $SNMPSTRING"
				fi

				FOUNDTYPE=2
			fi
		else
			if [ $DEBUG -gt 0 ]; then
				echo "Found Version 1 for $SNMPSTRING"
			fi

			FOUNDTYPE=1
		fi


		if [ $FOUNDTYPE -gt 0 ]; then
			PrintTabs "$SNMPSTRING\tVersion $FOUNDTYPE"
			NUMFOUND=$(( NUMFOUND + 1 ))
		fi
	done

	echo "[`date`] Finished mapping $TARGET.  Tested $TESTCOUNT strings, found $NUMFOUND matched names."
fi


