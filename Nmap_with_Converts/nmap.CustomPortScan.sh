#!/bin/sh

# --------------- Functions -------------------------
ShowUsage() {
  echo "usage: $0 <target> <base descriptor> [--no-microsoft] [--ping-first]"
  echo "If a base descriptor is provided, nmap generates "
  echo "all three output formats with the specified base name."
  echo "If --no-microsoft is specified, 135-139 and 445 are not scanned."
  echo "If --ping-first is specified, nmap is not run with -Pn"
  echo "Note: these parameters must be AFTER the target and base descriptor but can be in any order."
  echo ""
  echo "Target can be specified as file:<file> to use an input file of hosts"
  echo ""
}

EXPECTED_ARGS=2

if [ $# -lt $EXPECTED_ARGS ];then
  ShowUsage
  exit 1
fi

SCANMICROSOFT=1
PINGFIRST=0

for i in $*
do
	case $i in
	--help)
		ShowUsage
		exit 1
	;;
	--no-microsoft)
		SCANMICROSOFT=0
	;;
	--ping-first)
		PINGFIRST=1
	;;
  	esac
done

if [ $PINGFIRST -eq 0 ]; then
	# Don't ping first
	DONTSCANPARM="-Pn"
else
	# enable this to allow ping checks
	DONTSCANPARM=""
fi

if [ $SCANMICROSOFT -eq 1 ]; then
# This port list includes SIP, SIP-TLS, H.323, IAX1, IAX2, SKINNY, Microsoft Lync ports, etc.
PORTLIST="53,123,135-139,1434,5060,5061,T:20,21-26,37,38,42,49,67-69,79,80-82,88,100,106,110-113,119,120,143,144,158,162,177,179,192,199,207,217,254,255,280,311,363,389,402,407,427,434,443,444,445,464,465,497,502,512-520,539,543,544,548,559,587,593,623,625,626,631,636,639,643,646,657,664,682-689,764,767,772-776,780,781,782,786,787,789,800,808,814,826,829,838,873,902,903,944,959,965,983,989-1001,1007,1008,1012-1060,1064-1072,1080,1081,1087,1088,1090,1100,1101,1105,1110,1124,1200,1214,1234,1241,1346,1419,1433,1455,1457,1484,1485,1521,1522,1524,1645,1646,1701,1718,1719,1720,1723,1731,1755,1761,1782,1801,1804,1812,1813,1885,1886,1900,1901,1993,1998,2000-2002,2005,2048,2049,2051,2103,2105,2107,2121,2148,2160,2161,2222,2223,2343,2345,2362,2383,2401,2601,2717,2869,2967,3000,3001,3052,3128,3130,3260,3283,3296,3306,3343,3389,3401,3456,3457,3527,3659,3664,3689,3690,3702,3703,3986,4000,4001,4008,4045,4444,4500,4530,4569,4666,4672,4786,4899,5000,5001,5002,5003,5009,5010,5036,5050,5051,5062-5076,5080,5081,5082,5093,5101,5120,5190,5222,5223,5351,5353,5355,5357,5432,5500,5555,5631,5632,5666,5800,5900,5901,6000,6001,6002,6004,6050,6101-6103,6112,6346,6347,6600,6646,6665,6679, 6970,6971,7000,7937,7938,8000,8001,8008,8009,8010,8031,8057,8058,8080,8081,8181,8193,8404,8443-8445,8888,8900,9000,9001,9020,9090,9100-9103,9199,9200,9370,9876,9877,9950,9990,9999,10000,U:161,500"

else
# This version does not include the Microsoft ports:
PORTLIST="53,123,1434,5060,5061,T:20,21-26,37,38,42,49,67-69,79,80-82,88,100,106,110-113,119,120,143,144,158,162,177,179,192,199,207,217,254,255,280,311,363,389,402,407,427,434,443,444,464,465,497,502,512-520,539,543,544,548,559,587,593,623,625,626,631,636,639,643,646,657,664,682-689,764,767,772-776,780,781,782,786,787,789,800,808,814,826,829,838,873,902,903,944,959,965,983,989-1001,1007,1008,1012-1060,1064-1072,1080,1081,1087,1088,1090,1100,1101,1105,1110,1124,1200,1214,1234,1241,1346,1419,1433,1455,1457,1484,1485,1521,1522,1524,1645,1646,1701,1718,1719,1720,1723,1731,1755,1761,1782,1801,1804,1812,1813,1885,1886,1900,1901,1993,1998,2000-2002,2005,2048,2049,2051,2103,2105,2107,2121,2148,2160,2161,2222,2223,2343,2345,2362,2383,2401,2601,2717,2869,2967,3000,3001,3052,3128,3130,3260,3283,3296,3306,3343,3389,3401,3456,3457,3527,3659,3664,3689,3690,3702,3703,3986,4000,4001,4008,4045,4444,4500,4530,4569,4666,4672,4786,4899,5000,5001,5002,5003,5009,5010,5036,5050,5051,5062-5076,5080,5081,5082,5093,5101,5120,5190,5222,5223,5351,5353,5355,5357,5432,5500,5555,5631,5632,5666,5800,5900,5901,6000,6001,6002,6004,6050,6101-6103,6112,6346,6347,6600,6646,6665,6679, 6970,6971,7000,7937,7938,8000,8001,8008,8009,8010,8031,8057,8058,8080,8081,8181,8193,8404,8443-8445,8888,8900,9000,9001,9020,9090,9100-9103,9199,9200,9370,9876,9877,9950,9990,9999,10000,U:161,500"
fi


TARGET="$1"
BASEDESCRIPTOR="$2"

echo "$TARGET" | grep -iq "^file:"

if [ $? -eq 0 ]; then
	# is a file designator
	NETFILE=`echo "$TARGET" | sed "s|file:||" | sed "s|FILE:||"`

	if [ ! -e $NETFILE ]; then
		echo "ERROR: Unable to find file '$NETFILE'"
		exit 2
	fi

	# Base Descriptor.  Output to files.
	# Full for newest nmap: nmap -Pn -sV -T3 -A -F  --scan-delay 2ms --max-retries 1 --host-timeout 180m --data-length 31 --version-intensity 3 -sS -sU -oA $BASEDESCRIPTOR $TARGET
	# Full from file: nmap -Pn -sV -T3 -A -F  --scan-delay 2ms --max-retries 1 --host-timeout 180m --data-length 31 --version-intensity 3 -sS -sU -oA $BASEDESCRIPTOR -iL $TARGETFILE
# Took -sC script scan out because it was too "noisy"
	nmap $DONTSCANPARM -n -sV -T3 -O -p "$PORTLIST" --max-retries 2 --version-intensity 3 -sT -sU -oA $BASEDESCRIPTOR -iL $NETFILE
else
	nmap $DONTSCANPARM -n -sV -T3 -O -p "$PORTLIST"  --max-retries 2 --version-intensity 3 -sT -sU -oA $BASEDESCRIPTOR $TARGET
fi


