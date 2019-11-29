#!/bin/bash

# You can use upstart to run upstart scripts in /etc/init  (.conf upstart scripts)
# start, stop, and status commands can then be used (from the upstart module)

# a script like this would do the trick:
# description "moloch"
# start on runlevel [2345]
# exec /usr/bin/moloch.start.sh


# Start elasticsearch

# Check if it's already running first...
ISRUNNING=`ps aux | grep moloch | grep elasticsearch | grep -v "^$" | wc -l`

if [ $ISRUNNING -eq 0 ]; then
	echo "[`date`] Starting elasticsearch..."

	cd /data/moloch/elasticsearch-2.2.2
	ulimit -a
	# Uncomment if using Sun Java for better memory utilization
	export JAVA_OPTS="-XX:+UseCompressedOops"
	export ES_HOSTNAME=`hostname -s`
	# ES_HEAP_SIZE=1G bin/elasticsearch -Des.config=/data/moloch/etc/elasticsearch.yml > /data/moloch/logs/elasticsearch.log 2>&1 &
	ES_HEAP_SIZE=1G bin/elasticsearch -Des.insecure.allow.root=true > /data/moloch/logs/elasticsearch.log 2>&1 &

	sleep 30
else
	echo "[`date`] Elasticsearch already running..."
fi

# Start moloch packet capture process if not already running
# And stay in this loop until it starts!!!
while true
do
	ISRUNNING=`ps aux | grep "moloch-capture" | grep -v -e "grep" -e "^$" | wc -l`

	if [ $ISRUNNING -eq 0 ]; then
		echo "[`date`] Starting moloch packet capture process..."

		cd /data/moloch/bin
		rm -f /data/moloch/logs/capture.log.old
		mv /data/moloch/logs/capture.log /data/moloch/logs/capture.log.old
		/data/moloch/bin/moloch-capture -c /data/moloch/etc/config.ini > /data/moloch/logs/capture.log 2>&1 &

		sleep 30

		ISRUNNING=`ps aux | grep "moloch-capture" | grep -v -e "grep" -e "^$" | wc -l`

		if [ $ISRUNNING -gt 0 ]; then
			break
		else
			echo "[`date`] packet capture still not running.  Trying again..."
		fi
	else
		echo "[`date`] Moloch packet capture process already running..."
		break
	fi
done

# Start moloch viewer process
ISRUNNING=`ps aux | grep moloch | grep "viewer.js" | grep -v "^$" | wc -l`

if [ $ISRUNNING -eq 0 ]; then
echo "[`date`] Starting moloch viewer process..."

cd /data/moloch/viewer
	rm -f /data/moloch/logs/viewer.log.old
	mv /data/moloch/logs/viewer.log /data/moloch/logs/viewer.log.old
	export NODE_ENV=production
	exec /data/moloch/bin/node /data/moloch/viewer/viewer.js -c /data/moloch/etc/config.ini > /data/moloch/logs/viewer.log 2>&1 &
else
	echo "[`date`] Moloch viewer process already running..."
fi

echo ""
echo "[`date`] Moloch Processes:"
ps aux | grep moloch | grep -v grep
echo ""

# default username/password is admin/admin if not changed.
echo "[`date`] Done.  Browse to https://localhost:8005/ to view interface..."
