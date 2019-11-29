#!/bin/bash

FILES=`ls -1 *.software.txt *.services.txt *.processes.txt 2>/dev/null | sort -u`
NUMFILES=`echo "$FILES" | wc -l`

if [ $NUMFILES -eq 0 ]; then
	echo "ERROR: Unable to find software files."
	exit 1
fi

echo "[`date`] Started processing files in `pwd`..."

echo "[`date`] Checking for analysis results directory..."

if [ ! -e analysis ]; then
	mkdir analysis
fi

cd analysis

echo "[`date`] Cleaning up any results from past runs..."
if [ -e os_list.txt ]; then
	rm os_list.txt
fi

if [ -e os_computer_list.txt ]; then
	rm os_computer_list.txt
fi

if [ -e software_list.txt ]; then
	rm software_list.txt
fi

if [ -e software_computer_list.txt ]; then
	rm software_computer_list.txt
fi

if [ -e software_list.tmp ]; then
	rm software_list.tmp
fi

if [ -e service_list.tmp ]; then
	rm service_list.tmp
fi

if [ -e service_list.txt ]; then
	rm service_list.txt
fi

if [ -e service_computer_list.txt ]; then
	rm service_computer_list.txt
fi

if [ -e process_list.tmp ]; then
	rm process_list.tmp
fi

if [ -e process_list.txt ]; then
	rm process_list.txt
fi

if [ -e process_computer_list.txt ]; then
	rm process_computer_list.txt
fi

if [ -e messages.txt ]; then
	rm messages.txt
fi

echo "[`date`] Started processing $NUMFILES files..."
echo "[`date`] Started processing $NUMFILES files..." > messages.txt

IFS_BAK=$IFS
IFS="
"

i=0
MAXTHREADS=50

for CURFILE in $FILES; do
	i=$((i+1))
	CURCOMPUTER=`echo "$CURFILE" | sed "s|\..*||g"`

	echo "[`date`] ($i/$NUMFILES) Processing $CURCOMPUTER: $CURFILE..."

	audit-results-processor-thread_helper.sh $CURFILE $CURCOMPUTER &
	
	while true; do
		RUNNINGCOUNT=`ps aux | grep audit-results-processor-thread_helper | grep -v grep | wc -l`
		if [ $RUNNINGCOUNT -ge $MAXTHREADS ]; then
			sleep 10s
		else
			break
		fi
	done

done

echo "[`date`] Waiting for parallel processing to finish..."

while true; do
	RUNNINGCOUNT=`ps aux | grep audit-results-processor-thread_helper | grep -v grep | wc -l`
	if [ $RUNNINGCOUNT -ge 1 ]; then
		sleep 10s
	else
		break
	fi
done

echo "[`date`] Threads have finished.  Consolidating data..."
mv process_computer_list.txt process_computer_list.tmp
echo -e "Computer\tName\tPid\tPri\tExe Path" > process_computer_list.txt
cat process_computer_list.tmp >> process_computer_list.txt
rm process_computer_list.tmp
sed -i 's|\\\\|\\|g' process_computer_list.txt

cat os_list.tmp | sort -iu > os_list.txt
rm os_list.tmp 2>/dev/null

cat software_list.tmp | sort -iu > software_list.txt
rm software_list.tmp 2>/dev/null

cat service_list.tmp | sort -iu > service_list.txt
rm service_list.tmp 2>/dev/null

cat process_list.tmp | sort -iu >> process_list.txt
rm process_list.tmp 2>/dev/null

echo "[`date`] Done processing $NUMFILES files..."
echo "[`date`] Done processing $NUMFILES files..." >> messages.txt
IFS=$IFS_BAK
IFS_BAK=

