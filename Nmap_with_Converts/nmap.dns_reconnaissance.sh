#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <DNS Domain | domain file> <in-scope network file - NMAP format> <in-scope network file start/end format> <output directory>"
	echo "$0 will attempt to automatically discover DNS domains associated with the specified domain, perform DNS queries, and sort through discovered hosts to come up with a basic reconnaissance report."
	echo ""
	echo "The in-scope network start/end file should be in the format (one per line) <starting IP> <ending IP> rather than the nmap <subnet>/prefix or other formats in the nmap-style in-scope file."
	echo "     ex: 192.168.1.10 192.168.1.200"
	echo ""
}

if [ $# -lt 4 ]; then
	ShowUsage
	exit 1
fi

BASEDOMAIN=$1
DOMAINSFROMFILE=0

NMAPFILE="$2"
STARTENDIPFILE="$3"
OUTPUTDIR="$4"

# -------------  Validity Checks ---------------------
if [ ! -e $NMAPFILE ]; then
	echo "ERROR: Unable to find $NMAPFILE"
	exit 1
fi

if [ ! -e $STARTENDIPFILE ]; then
	echo "ERROR: Unable to find $STARTENDIPFILE"
	exit 2
fi

if [ ! -e $OUTPUTDIR ]; then
	echo "ERROR: $OUTPUTDIR does not exist."
	exit 3
fi

which ip.inranges.sh > /dev/null

if [ $? -gt 0 ]; then
	echo "ERROR: Unable to find supporting script ip.inranges.sh"
	exit 4
fi

cd $OUTPUTDIR

IFS_BAK=$IFS
IFS="
"

# -------------  Build Domain List ---------------------
if [ -e $BASEDOMAIN ]; then
	DOMAINS=`cat $BASEDOMAIN | grep -v "^$"`
	DOMAINSFROMFILE=1
else
	DOMAINS=$BASEDOMAIN
fi

# Google for other related domains based on address
# It was determined that this really needed to be provided by the client or
# manually gathered through Google / reconnaissance.  Too difficult to "scrape" 
# Google results accurately/consistently at this time.

# -------------  Perform Per-domain email and host lookups ---------------------

# Run nmap.dnsmap.sh on each domain and get hosts into hosts file
echo "$DOMAINS" > domains.txt

mkdir dns 2>/dev/null
cd dns
nmap.dnsmap.multipledomains.sh ../domains.txt

if [ -e ../all_hosts_raw.txt ]; then
	rm ../all_hosts_raw.txt
fi

cat *.hosts.txt | grep -v "^$" >> ../all_hosts_raw.txt
cd ..

# -------------  Perform reverse (PTR) ---------------------
RANGES=`cat $STARTENDIPFILE | grep -v "^$"`
cd dns

for CURRANGE in $RANGES; do
	MINIP=`echo "$CURRANGE" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | head -1`
	MAXIP=`echo "$CURRANGE" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | tail -1`

	FIRST3OCTETS=`echo "$MINIP" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
	FIRST4THOCTET=`echo "$MINIP" | sed "s|$FIRST3OCTETS\.||"`
	LAST4THOCTET=`echo "$MAXIP" | sed "s|$FIRST3OCTETS\.||"`

	dns.lookup.PTR_Range.sh $FIRST3OCTETS $FIRST4THOCTET $LAST4THOCTET > $FIRST3OCTETS.ptr.txt

	PTRRECS=`cat $FIRST3OCTETS.ptr.txt`
	for CURPTR in $PTRRECS; do
		HASDOMAIN=0
		# if a PTR record includes a known domain add it to the hosts list.
		for CURDOMAIN in $DOMAINS; do
			INPTR=`echo "$CURPTR" | grep "$CURDOMAIN" | wc -l`
			if [ $INPTR -gt 0 ]; then
				echo "$CURPTR" >> ../all_hosts_raw.txt
			fi
		done	
	done
done

# -------------  Sort through hosts results ---------------------

# Sort through hosts file entries and compare to in-scope start/end file
cd ..

ALLHOSTS=`cat all_hosts_raw.txt | sort -u`

for CURHOST in $ALLHOSTS; do
	CURIP=`echo "$CURHOST" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
	
	ip.inranges.sh $STARTENDIPFILE $CURIP > /dev/null

	if [ $? -eq 0 ]; then
		echo "$CURHOST" >> all_hosts_in-range.txt
	else
		echo "$CURHOST" >> all_hosts_out-of-scope.txt
	fi
done

# -------------  Do Google Searches ---------------------

# Do Google searches on discovered domains
mkdir google 2>/dev/null
cd google

google.search_multipledomains.sh ../domains.txt

cd ..

IFS=$IFS_BAK
IFS_BAK=


