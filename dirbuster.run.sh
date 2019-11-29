#!/bin/bash

ShowUsage () {
	echo ""
	echo "Usage: $0 --reportfile=<file> [--maxtime=<max time>] [--dictfile=<dictfile>] [--scantype=<docs|standard|full>] <url>"
	echo "or: $0 --list"
	echo ""
	echo "$0 Runs dirbuster against the specified target."
	echo ""
	echo "Parameters:"
	echo "--help                 This screen"
	echo "--reportfile=<file>    The output text file's name"
	echo "--maxtime=<max time>   The maximum time dirbuster is allowed to run.  This can be specified in 10s,2h,3d format"
	echo "                       The default is 10h"
	echo "--scantype=<docs (default)|standard|full> Determines the file extensions and default dictionary file used for the scan."
	echo "                       Docs only searches for jsp,js,cs,htm,html,asp,aspx,php,pl,form,do,doc,docx,xls,xlsx,txt,"
	echo "                       ppt,pdf,log,nsf,mdb,bak,etc.  standard and full add progressively more extensions but will"
	echo "                       increase runtime."
	echo "--dictfile=<dictfile>  Alternate dictionary file.  Default is dirbuster's directory-list-2.3-small.txt file"
	echo "<url>                  The site to test (e.g. http://mysite.com or https://www.mysite.com"
	echo "--list                 List dictionaries and their number of lines in the /opt/dirbuster directory."
	echo ""
}

TIMEOUT="10h"
REPORTFILE=""
DICTIONARYFILE="/opt/dirbuster/directory-list-2.3-small.txt"
URL=""

DOCEXT="jsp,js,cs,htm,html,asp,aspx,php,pl,form,do,doc,docx,xls,xlsx,txt,ppt,pdf,log,nsf,mdb,bak"
STDEXT="_,asa,ashx,asmx,asp,aspx,axd,bak,bakup,bat,c,cfm,cs,cgi,com,cs,dll,do,doc,docx,exe,form,htm,html,inc,java,js,jsa,jsp,log,mdb,nsf,o,old,php,pl,plx,ppt,pptx,reg,sav,saved,shtml,sql,tar,tar.gz,tgz,tmp,txt,xml,xls,xlsx,zip"
FULLEXT="_,asa,ashx,asmx,asp,aspx,axd,bak,bakup,bat,c,cfm,cs,cgi,com,cs,dll,do,doc,docx,exe,form,htm,html,inc,java,js,jsa,jsp,log,mdb,nsf,o,old,php,pl,plx,ppt,pptx,reg,sav,saved,sh,shtml,sql,tar,tar.gz,tgz,tmp,txt,vb,vbs,xml,xls,xlsx,zip"
SCANTYPE="doc file extension"

FILETYPELIST=`echo "$DOCEXT"`

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

for i in $*
do
	case $i in
	--help)
		ShowUsage
		exit 1
	;;
	--list)
		echo ""
		echo "Dictionary files"
		echo -e "Entries\tFile"
		DICTIONARIES=`find /opt/dirbuster -iname "directory*" -exec wc -l {} \;`

		DICTIONARIES=`echo "$DICTIONARIES" | sed 's| |\t|g' | sort -g`
		NUMDICT=`echo "$DICTIONARIES" | wc -l`
		echo "$DICTIONARIES"
		echo "Total: $NUMDICT dictionaries found."
		echo ""
		exit 0
	;;
	--scantype=*)
		SCANTYPE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`

		case $SCANTYPE in
		docs|Docs|DOCS|doc)
			FILETYPELIST=`echo "$DOCEXT"`
		;;
		standard|Standard|std)
			FILETYPELIST=`echo "$STDEXT"`
			SCANTYPE="standard file extension"
		;;
		Full|full|FULL)
			FILETYPELIST=`echo "$FULLEXT"`
			SCANTYPE="full file extenstion"
		;;
		esac
	;;
	--dictfile=*)
		DICTIONARYFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--reportfile=*)
		REPORTFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--maxtime=*)
		TIMEOUT=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	*)
		URL=$i
	;;
	esac
done

if [ ${#DICTIONARYFILE} -eq 0 ]; then
	echo "ERROR: Unable to find the dictionary file $DICTIONARYFILE."
	exit 2
fi
if [ ${#REPORTFILE} -eq 0 ]; then
	echo "ERROR: Please specify a report file."
	exit 2
fi

if [ ${#URL} -eq 0 ]; then
	echo "ERROR: Please specify a URL."
	exit 3
fi

if [ -e $REPORTFILE ]; then
	rm -f $REPORTFILE
fi

STARTTIME=`date`
echo "Starting a $SCANTYPE dirbuster scan of $URL at $STARTTIME"
timeout $TIMEOUT java -jar /opt/dirbuster/DirBuster-0.12.jar -t 90 -H -u $URL -e "$FILETYPELIST" -l $DICTIONARYFILE -r $REPORTFILE
ENDTIME=`date`
echo "Completed dirbuster scan of $1 at $ENDTIME"

if [ -e $REPORTFILE ]; then
	echo "" >> $REPORTFILE
	echo "$SCANTYPE Scan of $URL started at $STARTTIME and finished (or timed out) at $ENDTIME" >> $REPORTFILE
fi

