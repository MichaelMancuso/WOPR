#!/bin/bash
shopt -s expand_aliases

IFS_BAK=$IFS
IFS="
"

# Add -e filters to remove other IP's

alias filterip='grep -v -e "71.244.105.50"'

CURTIMESTAMP=`date +%Y-%m-%d-%H-%M-%S`
COUNTRYLOGFILE=`echo "/tmp/honeypot_analysis.country.$CURTIMESTAMP.txt"`

LOG="/var/log/apache2/access.log"
SOURCEIPS=`cat $LOG | strings | grep -v awstats | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -v -E -e "172\.22\.16\.[0-9]{1,3}" -e "172\.22\.1[2-5]\.[0-9]{1,3}"  -e "192\.168\.[0-9]{1,3}\.[0-9]{1,3}" | filterip | sort -u`
NUMIPS=`echo "$SOURCEIPS" | grep -v "^$" | wc -l`
echo ""
echo "[`date`] Apache http attack sources ($NUMIPS entries)"
echo "Last Seen	Country	GeoLocation	IP	Hits	First Seen"

OUTPUTTABLE=""

for CURIP in $SOURCEIPS
do
	COUNTRYSHORT=`geoiplookup -f /usr/share/GeoIP/GeoIP.dat $CURIP 2>&1 | grep "GeoIP Country Edition:" | sed "s|GeoIP Country Edition: ||" | cut -f2 -d","`
	COUNTRYLONG=`geoiplookup -f /usr/share/GeoIP/GeoLiteCity.dat $CURIP | sed "s|^GeoIP .*: ||" | cut -f1-4 -d"," | sed "s|, (null)||g"`
	COUNTRY=`echo "$COUNTRYSHORT	$COUNTRYLONG" | sed "s|^ ||g"`
	HITS=`cat $LOG | grep -v awstats | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -v -e "172\.22\.16\.[0-9]{1,3}" -e "172\.22\.1[2-5]\.[0-9]{1,3}"  -e "192\.168\.[0-9]{1,3}\.[0-9]{1,3}" | grep "^$CURIP$" | wc -l`
	FIRSTSEEN=`cat $LOG | grep "$CURIP" | grep -Po "\[.*?\-0500\]" | sed "s|\[||g" | sed "s|\]||g" | sort | head -1`
	LASTSEEN=`cat $LOG | grep "$CURIP" | grep -Po "\[.*?\-0500\]" | sed "s|\[||g" | sed "s|\]||g" | sort | tail -1`
	NEWLINE=`echo "$LASTSEEN	$COUNTRY	$CURIP	$HITS	$FIRSTSEEN"`
	
	for i in $(seq 1 $HITS)
	do
		echo "$COUNTRYSHORT" >> $COUNTRYLOGFILE
	done
	
	OUTPUTTABLE=`echo -e "$OUTPUTTABLE\n$NEWLINE"`
done

echo "$OUTPUTTABLE" | grep -v "^$" | sort

echo ""

if [ -e /var/log/apache2/access_ssl.log ]; then
	LOG="/var/log/apache2/access_ssl.log"
	SOURCEIPS=`cat $LOG  | strings | grep -v awstats | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -v -E -e "172\.22\.16\.[0-9]{1,3}" -e "172\.22\.1[2-5]\.[0-9]{1,3}"  -e "192\.168\.[0-9]{1,3}\.[0-9]{1,3}" | filterip | sort -u`
	NUMIPS=`echo "$SOURCEIPS" | grep -v "^$" | wc -l`
	echo ""
	echo "[`date`] Apache https attack sources ($NUMIPS entries)"
	echo "Last Seen	Country	GeoLocation	IP	Hits	First Seen"

	OUTPUTTABLE=""

	for CURIP in $SOURCEIPS
	do
		COUNTRYSHORT=`geoiplookup -f /usr/share/GeoIP/GeoIP.dat $CURIP 2>&1 | grep "GeoIP Country Edition:" | sed "s|GeoIP Country Edition: ||" | cut -f2 -d","`
		COUNTRYLONG=`geoiplookup -f /usr/share/GeoIP/GeoLiteCity.dat $CURIP | sed "s|^GeoIP .*: ||" | cut -f1-4 -d"," | sed "s|, (null)||g"`
		COUNTRY=`echo "$COUNTRYSHORT	$COUNTRYLONG" | sed "s|^ ||g"`
		HITS=`cat $LOG | grep -v awstats | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -v -e "172\.22\.16\.[0-9]{1,3}" -e "172\.22\.1[2-5]\.[0-9]{1,3}"  -e "192\.168\.[0-9]{1,3}\.[0-9]{1,3}" | grep "^$CURIP$" | wc -l`
		FIRSTSEEN=`cat $LOG | grep "$CURIP" | grep -Po "\[.*?\-0500\]" | sed "s|\[||g" | sed "s|\]||g" | sort | head -1`
		LASTSEEN=`cat $LOG | grep "$CURIP" | grep -Po "\[.*?\-0500\]" | sed "s|\[||g" | sed "s|\]||g" | sort | tail -1`
		NEWLINE=`echo "$LASTSEEN	$COUNTRY	$CURIP	$HITS	$FIRSTSEEN"`


		for i in $(seq 1 $HITS)
		do
			echo "$COUNTRYSHORT" >> $COUNTRYLOGFILE
		done
		
		OUTPUTTABLE=`echo -e "$OUTPUTTABLE\n$NEWLINE"`
	done

	echo "$OUTPUTTABLE" | grep -v "^$" | sort

	echo ""
fi

LOG="/opt/honeypots/cowrie-ssh/log/cowrie.log*"
SOURCEIPS=`cat $LOG  | strings | grep -aEo "New connection: [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -Ev -e "172\.22\.16\.[0-9]{1,3}" -e "172\.22\.1[2-5]\.[0-9]{1,3}" -e "192\.168\.[0-9]{1,3}\.[0-9]{1,3}" | filterip | sort -u`
NUMIPS=`echo "$SOURCEIPS" | grep -v "^$" | wc -l`
echo "[`date`] SSH connection sources ($NUMIPS entries)"
echo "Last Seen	Country	GeoLocation	IP	Hits	First Seen	Linger Time (sec)"

OUTPUTTABLE=""
LOGSTRINGS=`cat $LOG | strings`

for CURIP in $SOURCEIPS
do
	COUNTRYSHORT=`geoiplookup  -f /usr/share/GeoIP/GeoIP.dat $CURIP 2>&1 | grep "GeoIP Country Edition:" | sed "s|GeoIP Country Edition: ||" | cut -f2 -d","`
	COUNTRYLONG=`geoiplookup -f /usr/share/GeoIP/GeoLiteCity.dat $CURIP | sed "s|^GeoIP .*: ||" | cut -f1-4 -d"," | sed "s|, (null)||g"`
	COUNTRY=`echo "$COUNTRYSHORT	$COUNTRYLONG" | sed "s|^ ||g"`
#	HITS=`echo "$LOGSTRINGS" | grep -aEo "New connection: [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"  | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -Ev -e "172\.22\.16\.[0-9]{1,3}" -e "172\.22\.1[2-5]\.[0-9]{1,3}" -e "192\.168\.[0-9]{1,3}\.[0-9]{1,3}" | grep "^$CURIP$" | wc -l`
#	LASTSEEN=`echo "$LOGSTRINGS" | grep -aE "New connection: [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"  | grep -aEv -e "172\.22\.16\.[0-9]{1,3}" -e "172\.22\.1[2-5]\.[0-9]{1,3}"  -e "192\.168\.[0-9]{1,3}\.[0-9]{1,3}" | grep -aPo "^.*? \[" | sed "s| \[||g" | tail -1 | sed "s|-0500| -0500|"`
	HITS=`echo "$LOGSTRINGS" | grep -aEo "New connection: $CURIP" | wc -l`
	FIRSTSEEN=`echo "$LOGSTRINGS"  | strings | grep -aE "New connection: $CURIP" | grep -aPo "^.*? \[" | sed "s| \[||g" | sed "s|-0500| -0500|" | sort | head -1`
	LASTSEEN=`echo "$LOGSTRINGS" | grep -aE "New connection: $CURIP" | grep -aPo "^.*? \[" | sed "s| \[||g" | sed "s|-0500| -0500|" | sort | tail -1`
	FIRSTSEENSEC=`date -d "$FIRSTSEEN" +%s`
	LASTSEENSEC=`date -d "$LASTSEEN" +%s`
	LINGERTIME=$(( $LASTSEENSEC - $FIRSTSEENSEC ))
	NEWLINE=`echo "$LASTSEEN	$COUNTRY	$CURIP	$HITS	$FIRSTSEEN	$LINGERTIME"`

	for i in $(seq 1 $HITS)
	do
		echo "$COUNTRYSHORT" >> $COUNTRYLOGFILE
	done
	
	OUTPUTTABLE=`echo -e "$OUTPUTTABLE\n$NEWLINE"`
done

echo "$OUTPUTTABLE" | grep -v "^$" | sort

echo ""

LOGDIR="/opt/honeypots/cowrie-ssh/log"
LINES=""
FILES=`ls -1tr $LOGDIR/cowrie.log*`

TMPLOGFILE=`echo "/tmp/honeypot_analysis.loginattempts.$CURTIMESTAMP.txt"`
if [ -e $TMPLOGFILE ]; then
	rm $TMPLOGFILE
fi

for CURFILE in $FILES
do
	cat $CURFILE | strings | grep -a "^2" | grep -a -E "ssh-userauth.*login attempt" | grep -Ev -e "172\.22\.16\.[0-9]{1,3}" -e "172\.22\.1[2-5]\.[0-9]{1,3}"  -e "192\.168\.[0-9]{1,3}\.[0-9]{1,3}" | filterip >> $TMPLOGFILE
done

#SOURCEIPS=`cat $TMPLOGFILE | grep -aE "ssh-userauth.*login attempt" | grep -aEo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -Ev -e "172\.22\.16\.[0-9]{1,3}" -e "172\.22\.1[2-5]\.[0-9]{1,3}"  -e "192\.168\.[0-9]{1,3}\.[0-9]{1,3}" | filterip | sort -u`
SOURCEIPS=`cat $TMPLOGFILE | strings | grep -aEo ",[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\]" | sed "s|,||g" | sed "s|\]||g" | sort -u`
NUMIPS=`echo "$SOURCEIPS" | grep -v "^$" | wc -l`
echo "[`date`] SSH authentication sources ($NUMIPS entries)"
echo "Last Seen	Country	GeoLocation	IP	Logons	First Seen	Linger Time (sec)"

OUTPUTTABLE=""
LOGSTRINGS=`cat $TMPLOGFILE | strings`

for CURIP in $SOURCEIPS
do
	COUNTRYSHORT=`geoiplookup  -f /usr/share/GeoIP/GeoIP.dat $CURIP 2>&1 | grep "GeoIP Country Edition:" | sed "s|GeoIP Country Edition: ||" | cut -f2 -d","`
	COUNTRYLONG=`geoiplookup -f /usr/share/GeoIP/GeoLiteCity.dat $CURIP | sed "s|^GeoIP .*: ||" | cut -f1-4 -d"," | sed "s|, (null)||g"`
	COUNTRY=`echo "$COUNTRYSHORT	$COUNTRYLONG" | sed "s|^ ||g"`
	HITS=`echo "$LOGSTRINGS" | grep -aE "ssh-userauth.*login attempt"  | grep -aEo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep "^$CURIP$" | wc -l`
	FIRSTSEEN=`echo "$LOGSTRINGS" | grep -aE "ssh-userauth.*login attempt" | grep ",$CURIP]" | grep -Po "^.*? \[" | sed "s| \[||g" | sed "s|-0500| -0500|" | sort | head -1`
	LASTSEEN=`echo "$LOGSTRINGS" | grep -aE "ssh-userauth.*login attempt" | grep ",$CURIP]" | grep -Po "^.*? \[" | sed "s| \[||g" | sed "s|-0500| -0500|" | sort | tail -1`
	FIRSTSEENSEC=`date -d "$FIRSTSEEN" +%s`
	LASTSEENSEC=`date -d "$LASTSEEN" +%s`
	LINGERTIME=$(( $LASTSEENSEC - $FIRSTSEENSEC ))
	NEWLINE=`echo "$LASTSEEN	$COUNTRY	$CURIP	$HITS	$FIRSTSEEN	$LINGERTIME"`
	OUTPUTTABLE=`echo -e "$OUTPUTTABLE\n$NEWLINE"`
done

echo "$OUTPUTTABLE" | grep -v "^$" | sort

echo ""

COUNTRIES=`cat $COUNTRYLOGFILE | sort -u | grep -v "^$"`
NUMCOUNTRIES=`cat $COUNTRYLOGFILE | sort -u | grep -v "^$" | wc -l`
OUTPUTTABLE=""

echo "[`date`] Country Connection Counts Across All Services ($NUMCOUNTRIES countries)"
echo "#	Country"
for CURCOUNTRY in $COUNTRIES
do
	NUMENTRIES=`cat $COUNTRYLOGFILE | grep -F "$CURCOUNTRY" | grep -v "^$" | wc -l`
	NEWLINE=`echo "$NUMENTRIES	$CURCOUNTRY"`
	OUTPUTTABLE=`echo -e "$OUTPUTTABLE\n$NEWLINE"`
done

echo "$OUTPUTTABLE" | grep -v "^$" | sort -rn

echo ""
COMBINATIONS=`cat $TMPLOGFILE | strings | filterip | grep -aEo "login attempt.*" | sed "s|login attempt ||g" | sed "s|\[||g" | sed "s|\]||g"| sort -u`

SUCCESSFULLOGONS=`cat $TMPLOGFILE | strings | grep -aE "ssh-userauth.*login attempt" | grep -aEo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -ai "success"`
NUMENTRIES=`echo "$SUCCESSFULLOGONS" | grep -v "^$" | wc -l`
echo "[`date`] SSH Successful Authentications ($NUMENTRIES entries)"
if [ $NUMENTRIES -gt 0 ]; then
echo "$SUCCESSFULLOGONS"
fi

echo ""

# COMBINATIONS=`cat /opt/honeypots/cowrie-ssh/log/cowrie.log | grep -aE "login attempt.*" | sed "s|\[.*,.,||g" | sed "s|\]||g" | sed "s|\[||g"`
echo "[`date`] SSH unique user/pass combinations (`echo "$COMBINATIONS" | wc -l` entries)"
echo "# of times seen	user/pass	outcome"

OUTPUTTABLE=""

# echo "$COMBINATIONS"
UNIQUEFILE="/tmp/honeypot_stats.unique.$CURTIMESTAMP.txt"
cat $TMPLOGFILE | strings | grep -aEo "login attempt.*" | sed "s|login attempt ||g" | sed "s|\[||g" | sed "s|\]||g" > $UNIQUEFILE

for CURLINE in $COMBINATIONS
do
#	GREPSTRING=`echo "$CURLINE"  | sed -E 's/([\\\^\*\.\(\)\[])/\\&/g' | sed -E 's/\|/\\\|/g' | sed 's|\!|\\\!|g' | sed 's|\$|\\\$|g'`
#	NUMENTRIES=`cat $TMPLOGFILE | grep -aEo "login attempt.*" | sed "s|login attempt ||g" | sed "s|\[||g" | sed "s|\]||g" | grep -E "$GREPSTRING" | wc -l`

#	NUMENTRIES=`cat $TMPLOGFILE | grep -aEo "login attempt.*" | sed "s|login attempt ||g" | sed "s|\[||g" | sed "s|\]||g" | grep -F "$CURLINE" | wc -l`
	NUMENTRIES=`cat $UNIQUEFILE | grep -F "$CURLINE" | wc -l`
	LOGLINE=`echo "$CURLINE" | sed "s| failed|\tfailed|g" | sed "s| success|\tsuccess|g"`
	NEWLINE=`echo "$NUMENTRIES	$LOGLINE"`
	OUTPUTTABLE=`echo -e "$OUTPUTTABLE\n$NEWLINE"`
done

echo "$OUTPUTTABLE" | grep -v "^$" | sort -nr

rm $UNIQUEFILE

echo ""

# COMBINATIONS=`cat /opt/honeypots/cowrie-ssh/log/cowrie.log | grep -aEo "login attempt.*" | sed "s|login attempt ||g" | sed "s|\[||g" | sed "s|\]||g"| sort -u`
COMBINATIONS=`cat $TMPLOGFILE | strings | filterip | grep -aE "login attempt.*" | sed "s|\[.*,.,||g" | sed "s|\]||g" | sed "s|\[||g"`
NUMCOMBOS=`echo "$COMBINATIONS" | grep -v "^$" | wc -l`
echo "[`date`] SSH user/pass attempts ($NUMCOMBOS entries)"

for CURLINE in $COMBINATIONS
do
	CURIP=`echo "$CURLINE" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
	COUNTRYSHORT=`geoiplookup  -f /usr/share/GeoIP/GeoIP.dat $CURIP 2>&1 | grep "GeoIP Country Edition:" | sed "s|GeoIP Country Edition: ||" | cut -f2 -d","`
	COUNTRYLONG=`geoiplookup -f /usr/share/GeoIP/GeoLiteCity.dat $CURIP | sed "s|^GeoIP .*: ||" | cut -f1-4 -d"," | sed "s|, (null)||g"`
	COUNTRY=`echo "$COUNTRYSHORT ($COUNTRYLONG)" | sed "s|^ ||g" | sed "s| $||g"`
	CURLINE=`echo "$CURLINE" | sed "s|-0500 |-0500\t|g" | sed "s| login attempt |\t|g" | sed "s| failed|\tfailed|g" | sed "s| success|\tsuccess|g" | sed "s|SSHService ssh-userauth on HoneyPotTransport,[0-9]*,||g" | sed "s|-0500| -0500|"`
	echo "$COUNTRY	$CURLINE"
done
echo ""

rm $TMPLOGFILE
rm $COUNTRYLOGFILE

echo "[`date`] Apache http last 30 non-private entries"
LOGENTRIES=`cat /var/log/apache2/access.log | grep -v awstats | filterip | grep -aEv -e "172\.22\.16\.[0-9]{1,3}" -e "172\.22\.1[2-5]\.[0-9]{1,3}" -e "192\.168\.[0-9]{1,3}\.[0-9]{1,3}" | tail -30`

for CURLINE in $LOGENTRIES
do
	CURIP=`echo "$CURLINE" | grep -Eo " [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} " | sed "s| ||g"`
	COUNTRYSHORT=`geoiplookup  -f /usr/share/GeoIP/GeoIP.dat $CURIP 2>&1 | grep "GeoIP Country Edition:" | sed "s|GeoIP Country Edition: ||" | cut -f2 -d","`
	COUNTRYLONG=`geoiplookup -f /usr/share/GeoIP/GeoLiteCity.dat $CURIP | sed "s|^GeoIP .*: ||" | cut -f1-4 -d"," | sed "s|, (null)||g"`
	COUNTRY=`echo "$COUNTRYSHORT ($COUNTRYLONG)" | sed "s|^ ||g"`
	CURLINE=`echo "$CURLINE" | sed "s|-0500 |-0500\t|g" | sed "s| login attempt |\t|g" | sed "s| failed|\tfailed|g" | sed "s| success|\tsuccess|g"`
	echo "$COUNTRY	$CURLINE"
done
echo ""

echo "[`date`] Apache https last 30 non-private entries"
LOGENTRIES=`cat /var/log/apache2/access_ssl.log | grep -v awstats | filterip | grep -aEv -e "172\.22\.16\.[0-9]{1,3}" -e "172\.22\.1[2-5]\.[0-9]{1,3}" -e "192\.168\.[0-9]{1,3}\.[0-9]{1,3}" | tail -30`

for CURLINE in $LOGENTRIES
do
	CURIP=`echo "$CURLINE" | grep -Eo " [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} " | sed "s| ||g"`
	COUNTRYSHORT=`geoiplookup  -f /usr/share/GeoIP/GeoIP.dat $CURIP 2>&1 | grep "GeoIP Country Edition:" | sed "s|GeoIP Country Edition: ||" | cut -f2 -d","`
	COUNTRYLONG=`geoiplookup -f /usr/share/GeoIP/GeoLiteCity.dat $CURIP | sed "s|^GeoIP .*: ||" | cut -f1-4 -d"," | sed "s|, (null)||g"`
	COUNTRY=`echo "$COUNTRYSHORT ($COUNTRYLONG)" | sed "s|^ ||g"`
	CURLINE=`echo "$CURLINE" | sed "s|-0500 |-0500\t|g" | sed "s| login attempt |\t|g" | sed "s| failed|\tfailed|g" | sed "s| success|\tsuccess|g"`
	echo "$COUNTRY	$CURLINE"
done
echo ""

IFS=$IFS_BAK
IFS_BAK=
