#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <program> [parameters]"
	echo "$0 will run the command <program> but will tell it to ignore the SIGHUP signal sent when a terminal session ends (e.g. an ssh session is closed)."
	echo ""
	echo "Note that this uses the built-in 'nohup' command.  Any command-line output will be redirected to HOME/nohup.out.  'disown -h' can also be used to dissociate already running processes"
	}

if [ $# -eq 0 ]; then
	ShowUsage
	
	exit 1
fi

	case $1 in
    	--help)
			ShowUsage
			exit 1
		;;
  	esac

echo "Running \"$@\""

nohup "$@"
