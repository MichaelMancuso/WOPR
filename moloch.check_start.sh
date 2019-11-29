#/bin/bash

NUMPROCS=`ps aux | grep moloch | grep -v grep | grep -e viewer -e java -e capture | wc -l`

if [ $NUMPROCS -lt 3 ]; then
	moloch.start.sh
fi

