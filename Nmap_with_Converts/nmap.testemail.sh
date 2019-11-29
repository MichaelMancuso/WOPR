#!/bin/bash

ShowUsage() {
	echo ""
	echo "Usage: $0 --internal=<Internal/recipient email address> --external=<external/sending email address> [--smtp-server=<smtp ip[:port]>] [--internal-name=<name>] [--external-name=<name>]"
	echo ""
	echo "Given an internal and external email address, $0 will attempt to:"
	echo "1. Open relay from <external> to <external>"
	echo "2. Spoofed relay from <internal> to <external>"
	echo "3. Internal address spoofing from the outside (<internal> to <internal>)"
	echo "   For this test, a fake jsmith@<domain> is used for the internal because "
	echo "   some anti-spam systems will increase the email score if sender=receiver."
	echo "4. Anti-malware check with EICAR file attached <external> to <internal>"
	echo ""
  	echo -e "\033[1mNotes:\033[0m"
	echo "- The EICAR file should be in /opt/eicar/eicar_com.zip available at http://www.eicar.org"
	echo ""
  	echo -e "\033[1mParameters:\033[0m"
	echo "--internal=<Internal target email address>  Where the email address provided is 'internal' to the targeted org."
	echo "--external=<external email address>         An external email address to source from. (e.g. jsmith@gmail.com)"
	echo ""
	echo "--smtp-server=<smtp ip>        IP address of the SMTP server to use (e.g. target SMTP server or your own)"
	echo "                               If not provided, ALL servers specified in the domain's MX record list for "
	echo "                               <internal target email> will be tested."
	echo "--internal-name=<name>         Optional recipient name for personalized message."
	echo "--external-name=<name>         Optional sender's name for personalized message."
	echo ""
  	echo -e "\033[1mExamples:\033[0m"
  	echo -e "\033[34m$0 --internal=jsmith@myclientsdomain.com --external=myname@mydomain.com --internal-name=John --external-name=Jason --smtp-server=10.1.1.70\033[0m"
	echo ""
}

# ---------- Main ------------

if [ $# -lt 3 ]; then
	# need at least sender, recipient, and smtp server or mx
	ShowUsage
	exit 1
fi

# Check environment:
if [ ! -e /usr/bin/sendemail.pl ]; then
	echo "ERROR: Unable to locate /usr/bin/sendemail.pl"
	exit 1
fi

if [ ! -e /usr/bin/sendemail-full.pl ]; then
	echo "ERROR: Unable to locate /usr/bin/sendemail-full.pl"
	exit 1
fi

# Set up parameters
INTERNALEMAIL=""
EXTERNALEMAIL=""
SMTPSERVER=""
USEMX=0
DOMAIN=""
RECIPIENTNAME=""
SENDERNAME=""

for i in $*
do
	case $i in
	--internal=*)
		INTERNALEMAIL=`echo $i | sed 's/[-a-zA-Z0-9]*=//' | sed "s|\"||g"`
	;;
	--external=*)
		EXTERNALEMAIL=`echo $i | sed 's/[-a-zA-Z0-9]*=//' | sed "s|\"||g"`
	;;
	--smtp-server=*)
		SMTPSERVER=`echo $i | sed 's/[-a-zA-Z0-9]*=//' | sed "s|\"||g" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}.*"`
	;;
	--internal-name=*)
		RECIPIENTNAME=`echo $i | sed 's/[-a-zA-Z0-9]*=//' | sed "s|\"||g"`
	;;
	--external-name=*)
		SENDERNAME=`echo $i | sed 's/[-a-zA-Z0-9]*=//' | sed "s|\"||g"`
	;;
	--help | *)
		ShowUsage
		exit 1
	;;
	esac
done

# Sanity check inputs
echo ""
echo "Sending with:"
echo "Internal/target email: $INTERNALEMAIL"
echo "External/sending email: $EXTERNALEMAIL"

if [ ${#INTERNALEMAIL} -eq 0 ]; then
	echo "Please provide an email address internal to the target."
	exit 2
fi

# extract domain
DOMAIN=`echo "$INTERNALEMAIL" | sed 's|.*@||'`
echo "DOMAIN: $DOMAIN"

if [ ${#DOMAIN} -eq 0 ]; then
	echo "ERROR: Unable to extract email domain from $INTERNALEMAIL."
	echo "Please check that the value is in the <user>@somedomain.com format."

	exit 2
fi

if [ ${#EXTERNALEMAIL} -eq 0 ]; then
	echo "Please provide an email address external to the target (e.g. @gmail.com)."
	exit 2
fi

if [ ! -e /opt/eicar/eicar_com.zip ]; then
	echo "ERROR: Unable to find EICAR virus test file at /opt/eicar/eicar_com.zip"
	exit 2
fi

if [ ${#SMTPSERVER} -eq 0 ]; then
	USEMX=1
fi

if [ $USEMX -eq 0 ]; then
	echo "$SMTPSERVER" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" > /dev/null

	if [ $? -gt 0 ]; then
		# Didn't find an IP

		echo "ERROR: Unable to determine SMTP server address from --smtp-server."
		exit 2
	fi

	SMTPSERVERLIST=$SMTPSERVER
else
	# get MX records
	NSRESULT=`nslookup -type=MX $DOMAIN`

	MXLIST=`echo "$NSRESULTS" | grep "internet address" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|\r||g"`
	NUMSERVERS=`echo "$MXLIST" | wc -l`

	if [ $NUMSERVERS -eq 0 ]; then
		echo "ERROR: Unable to retrieve mx records for $DOMAIN"
		echo "DEBUG: NSLOOKUP results"
		echo "$NSRESULT"
		
		exit 2
	else
		SMTPSERVERLIST=`echo "$MXLIST"`
	fi
fi

SMTPSERVERLIST=`echo "$SMTPSERVERLIST" | grep -v "^$"`
echo "SMTP Server(s):"
echo "$SMTPSERVERLIST"

for SMTPIP in $SMTPSERVERLIST
do
	if [ ${#RECIPIENTNAME} -gt 0 ]; then
		BODYTEXTBASE=`echo "$RECIPIENTNAME:<cr><cr>"`
	fi

	BODYTEXTBASE=`echo "$BODYTEXTBASE This is a test email of RELAYTYPE through $SMTPIP.  Please let me know if you receive this.<cr><cr>Thanks!<cr>"`

	if [ ${#SENDERNAME} -gt 0 ]; then
		BODYTEXTBASE=`echo "$BODYTEXTBASE $SENDERNAME<cr>"`
	fi

	# "1. Open relay from <external> to <external>"
	echo ""
	echo "Sending $EXTERNALEMAIL to $EXTERNALEMAIL via $SMTPIP..."
	BODYTEXT=`echo "$BODYTEXTBASE" | sed "s|RELAYTYPE|external-to-external relaying|" | sed 's|<cr>|\\n|g'`
	
#	echo "DEBUG: Message"
#	echo "$BODYTEXT"
#	exit 1

	/usr/bin/sendemail.pl $SMTPIP $EXTERNALEMAIL $EXTERNALEMAIL "External to external test for $DOMAIN" "$BODYTEXT"

	# "2. Spoofed relay from <internal> to <external>"
	echo ""
	echo "Sending $INTERNALEMAIL to $EXTERNALEMAIL via $SMTPIP..."
	BODYTEXT=`echo "$BODYTEXTBASE" | sed "s|RELAYTYPE|internal-to-external relaying|" | sed 's|<cr>|\\n|g'`
	/usr/bin/sendemail.pl $SMTPIP $INTERNALEMAIL $EXTERNALEMAIL "Internal to external test for $DOMAIN" "$BODYTEXT"

	# "3. Internal address spoofing from the outside (<internal> to <internal>)"
	echo ""
	FAKEINTERNAL=`echo "jsmith@$DOMAIN"`
	echo "Sending $FAKEINTERNAL to $INTERNALEMAIL via $SMTPIP..."
	BODYTEXT=`echo "$BODYTEXTBASE $EXTERNALEMAIL<cr>" | sed "s|RELAYTYPE|internal-to-internal relaying|" | sed 's|<cr>|\\n|g'`
	/usr/bin/sendemail.pl $SMTPIP $FAKEINTERNAL $INTERNALEMAIL "Internal to internal test for $DOMAIN" "$BODYTEXT"

	# "4. Anti-malware check with EICAR file attached <external> to <internal>"
	echo ""
	echo "Sending EICAR test from $EXTERNALEMAIL to $INTERNALEMAIL via $SMTPIP..."
	BODYTEXT=`echo "$BODYTEXTBASE" | sed "s|RELAYTYPE|malware delivery|" | sed 's|<cr>|\\n|g'`
	/usr/bin/sendemail-full.pl $SMTPIP $EXTERNALEMAIL $INTERNALEMAIL "EICAR test for $DOMAIN" "$BODYTEXT" /opt/eicar/eicar_com.zip

done

