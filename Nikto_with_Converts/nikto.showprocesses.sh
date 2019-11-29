#!/bin/bash

CheckForKeypress() {
	USER_INPUT=""
	read -t 1 -n 1 USER_INPUT 

	if [ ${#USER_INPUT} -gt 0 ]; then
		case $USER_INPUT in
		p)
			echo ""
			echo "Paused [`date`].  Press c to continue or q to quit."

			while true
			do
				USER_INPUT=""
				read -t 1 -n 1 USER_INPUT 
				if [ ${#USER_INPUT} -gt 0 ]; then
					case $USER_INPUT in
					c)
						echo "Continuing [`date`]..."
						break			
					;;
					q)
						echo "Quitting [`date`]."
						exit 1
					;;
					*)
						echo "Paused.  Press c to continue or q to quit."
					;;
					esac
				fi
			done
		;;
		q)
			echo "Quitting [`date`]."
			exit 1
		;;
		esac
	fi
}

while (true)
do
	NIKTOPROC=`ps -A | grep -E "nikto\.pl" | grep -Eo "^.[0-9]{1,}" | sed "s| ||g" | grep -Ev "^$"`
	NUMPROC=`echo "$NIKTOPROC" | grep -Ev "^$" | wc -l`

	if [ $NUMPROC -eq 0 ]; then
		exit 0
	fi

	echo "Checking for new processes [press q to quit]..."
	sleep 1s
	CheckForKeypress

	PROCLIST=`echo "$NIKTOPROC" | tr '\n' ',' | sed "s|,$||"`

	if [ $NUMPROC -gt 0 ]; then
		echo "Process List: $PROCLIST"
		top -p $PROCLIST -d 2 -n 15
	else
		echo "ERROR: No Nikto processes running."
	fi

done


