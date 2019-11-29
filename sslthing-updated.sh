#!/bin/bash

# 6/23/2014 - MKP Updated to note all RC4 ciphers as weak to align with industry vulnerability scanners (OpenVAS and Qualys are now reporting all RC4 as weak)
#

## sslthing.sh 20040621 by blh [at] blh.se

# Updated 02/2010 by mkp to include cipher strength
# and clean up sslthing.tmp file creation in whatever
# directory it was run from (moved to ~).

ShowUsage() {
  	echo "Usage: $0 [-v] host[:sslport]"
	echo ""
	echo "Where host is either hostname or ip address.  The default ssl port is 443 unless specified."
	echo "-v   Provides verbose output."
	echo ""
}

# --------------- Strength Function -----------
CipherStrength() {

	# $1 = cipher
	# $2 = bits
	# $3 = 1 for echo cr, 0 for none (echo -n)

	CIPHERSTRENGTH="Unknown"
	CIPHERNAME=`echo "$1" | sed "s| ||g"`

	case $CIPHERNAME in
	NULL-MD5)
		CIPHERSTRENGTH="No Security"
		;;
	NULL-SHA)
		CIPHERSTRENGTH="No Security"
		;;
	EXP-DES-CBC-SHA)
		CIPHERSTRENGTH="Weak Security"
		;;
	EXP-RC2-CBC-MD5)
		CIPHERSTRENGTH="Weak Security"
		;;
	EXP-RC4-MD5)
		CIPHERSTRENGTH="Weak Security"
		;;
	EXP1024-DHE-DSS-DES-CBC-SHA)
		CIPHERSTRENGTH="Weak Security"
		;;
	EXP1024-DHE-DSS-RC4-SHA)
		CIPHERSTRENGTH="Weak Security"
		;;
	EXP1024-DES-CBC-SHA)
		CIPHERSTRENGTH="Weak Security"
		;;
	EXP1024-RC4-SHA)
		CIPHERSTRENGTH="Weak Security"
		;;
	DES-CBC-SHA)
		CIPHERSTRENGTH="Weak Security"
		;;
	ADH-AES128-SHA)
		CIPHERSTRENGTH="Weak Security"
		;;
	ADH-AES256-SHA)
		CIPHERSTRENGTH="Weak Security"
		;;
	DH-DSS-AES128-SHA)
		CIPHERSTRENGTH="Strong Security"
		;;
	DH-RSA-AES128-SHA)
		CIPHERSTRENGTH="Strong Security"
		;;
	DHE-DSS-RC4-SHA)
		CIPHERSTRENGTH="Weak Security"
		;;
	DHE-DSS-AES128-SHA)
		CIPHERSTRENGTH="Strong Security"
		;;
	DHE-RSA-AES128-SHA)
		CIPHERSTRENGTH="Strong Security"
		;;
	RC4-MD5)
		CIPHERSTRENGTH="Weak Security"
		;;
	RC4-SHA)
		CIPHERSTRENGTH="Weak Security"
		;;
	AES128-SHA)
		CIPHERSTRENGTH="Strong Security"
		;;
	DES-CBC3-SHA)
		CIPHERSTRENGTH="Strong Security"
		;;
	DH-DSS-AES256-SHA)
		CIPHERSTRENGTH="Excellent Security"
		;;
	DH-RSA-AES256-SHA)
		CIPHERSTRENGTH="Excellent Security"
		;;
	DHE-DSS-AES256-SHA)
		CIPHERSTRENGTH="Excellent Security"
		;;
	DHE-RSA-AES256-SHA)
		CIPHERSTRENGTH="Excellent Security"
		;;
	AES256-SHA)
		CIPHERSTRENGTH="Excellent Security"
		;;
	DES-CBC3-MD5) 
		# - 168 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	RC2-CBC-MD5)
		# 128 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	DES-CBC-MD5)
		# 56 bits
		CIPHERSTRENGTH="Weak Security"
		;;
	EDH-RSA-DES-CBC3-SHA)
		# 168 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	EDH-DSS-DES-CBC3-SHA)
		# 168 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	EDH-RSA-DES-CBC-SHA)
		# 56 bits
		CIPHERSTRENGTH="Weak Security"
		;;
	EDH-DSS-DES-CBC-SHA)
		# 56 bits
		CIPHERSTRENGTH="Weak Security"
		;;
	EXP-EDH-RSA-DES-CBC-SHA)
		# 40 bits
		CIPHERSTRENGTH="Weak Security"
		;;
	EXP-EDH-DSS-DES-CBC-SHA)
		# 40 bits
		CIPHERSTRENGTH="Weak Security"
		;;
# Newly added:
	IDEA-CBC-MD5)
		# 128 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	ECDHE-RSA-AES256-SHA)
	# 256 bits
		CIPHERSTRENGTH="Excellent Security"
		;;
	ECDHE-ECDSA-AES256-SHA)
	# 256 bits
		CIPHERSTRENGTH="Excellent Security"
		;;
	DHE-RSA-CAMELLIA256-SHA)
	# 256 bits
		CIPHERSTRENGTH="Excellent Security"
		;;
	DHE-DSS-CAMELLIA256-SHA)
	# 256 bits
		CIPHERSTRENGTH="Excellent Security"
		;;
	ECDH-RSA-AES256-SHA)
	# 256 bits
		CIPHERSTRENGTH="Excellent Security"
		;;
	ECDH-ECDSA-AES256-SHA)
	# 256 bits
		CIPHERSTRENGTH="Excellent Security"
		;;
	CAMELLIA256-SHA)
	# 256 bits
		CIPHERSTRENGTH="Excellent Security"
		;;
	PSK-AES256-CBC-SHA)
	# 256 bits
		CIPHERSTRENGTH="Excellent Security"
		;;
	ECDHE-RSA-DES-CBC3-SHA)
	# 168 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	ECDHE-ECDSA-DES-CBC3-SHA)
	# 168 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	ECDH-RSA-DES-CBC3-SHA)
	# 168 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	ECDH-ECDSA-DES-CBC3-SHA)
	# 168 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	PSK-3DES-EDE-CBC-SHA)
	# 168 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	ECDHE-RSA-AES128-SHA)
	# 128 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	ECDHE-ECDSA-AES128-SHA)
	# 128 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	DHE-RSA-SEED-SHA)
	# 128 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	DHE-DSS-SEED-SHA)
	# 128 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	DHE-RSA-CAMELLIA128-SHA)
	# 128 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	DHE-DSS-CAMELLIA128-SHA)
	# 128 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	ECDH-RSA-AES128-SHA)
	# 128 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	ECDH-ECDSA-AES128-SHA)
	# 128 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	SEED-SHA)
	# 128 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	CAMELLIA128-SHA)
	# 128 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	IDEA-CBC-SHA)
	# 128 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	PSK-AES128-CBC-SHA)
	# 128 bits
		CIPHERSTRENGTH="Strong Security"
		;;
	ECDHE-RSA-RC4-SHA)
	# 128 bits
		CIPHERSTRENGTH="Weak Security"
		;;
	ECDHE-ECDSA-RC4-SHA)
	# 128 bits
		CIPHERSTRENGTH="Weak Security"
		;;
	ECDH-RSA-RC4-SHA)
	# 128 bits
		CIPHERSTRENGTH="Weak Security"
		;;
	ECDH-ECDSA-RC4-SHA)
	# 128 bits
		CIPHERSTRENGTH="Weak Security"
		;;
	PSK-RC4-SHA)
	# 128 bits
		CIPHERSTRENGTH="Weak Security"
		;;

    	*)
		CIPHERSTRENGTH="Unknown"
		# default / else
		;;
	esac

	echo "$CIPHERSTRENGTH" | grep -q "Unknown"

#	if [ "$CIPHERSTRENGTH"="Unknown" ]; then
	if [ $? -eq 0 ]; then
		# Key off of cipher strength

		case $2 in
		256)
			CIPHERSTRENGTH="Excellent Security"
		;;
		168)
			CIPHERSTRENGTH="Strong Security"
		;;
		128)
			CIPHERSTRENGTH="Strong Security"
		;;

		56)
			CIPHERSTRENGTH="Weak Security"
		;;
		40)
			CIPHERSTRENGTH="Weak Security"
		;;		
		esac
	fi

       	if [ $3 -eq 1 ]; then
       		echo -n [$CIPHERSTRENGTH] $1 - $2 bits...
	else
       		echo [$CIPHERSTRENGTH] $1 - $2 bits
	fi
}

# -------------- Main ------------------------

if [ $# -eq 0 ]; then
	ShowUsage
  	exit 1
fi

VERBOSE=0
SSLHOST=""

for i in $*
do
	case $i in
	-v)
		VERBOSE=1
	;;
	--help)
		ShowUsage
		exit 1
	;;
	*)
		SSLHOST=$i
	;;
	esac
done

if [ ${#SSLHOST} -eq 0 ]; then
	echo "ERROR: Please provide a host to scan."
	echo ""
	exit 3
fi

## Location of openssl
## ossl=/usr/sbin/openssl
if [ -e /usr/local/ssl/bin/openssl ]; then
	ossl=/usr/local/ssl/bin/openssl
else
	ossl=/usr/bin/openssl
fi

## Make a request (may be altered)
echo -e "GET / HTTP/1.1\n\n" > ~/sslthing.tmp

if [ ! -e ~/sslthing.tmp ]; then
	echo "Unable to create temporary file ~/sslthing.tmp."
	exit 1
fi

###### END OF CONFIGURATION #####

echo "$SSLHOST" | grep ":" > /dev/null

if [ $? -gt 0 ]; then
	SSLHOST=`echo "$SSLHOST:443"`
fi

if [ ! -e $ossl ]; then
  echo The path to openssl is wrong, please edit $0
  exit 2
fi

## Request available ciphers from openssl and test them
## SSLv2 was removed from general support in the latest version of openssl.  Test for this error:
$ossl ciphers -ssl2 -v 2>&1 | grep "^.*error.*ssl method passed:ssl_lib" > /dev/null

if [ $? -eq 0 ]; then
	# The error occurred.  It's not supported.
	echo "Testing SSL2..."
	echo "Unsupported by installed openssl library (this was changed in the latest release)"

	CIPHERLIST="-tls1 -ssl3"
else
	CIPHERLIST="-ssl2 -ssl3 -tls1"
fi

#for ssl in -ssl2 -ssl3 -tls1
for ssl in $CIPHERLIST
do
  echo `echo $ssl | cut -c2- | tr "a-z" "A-Z"`:
  $ossl ciphers $ssl -v | while read line
  do
    cipher=`echo $line | awk '{print $1}'`
    bits=`echo $line | awk '{print $5}' | cut -f2 -d\( | cut -f1 -d\)`
    if [ $2 ]; then
#      echo -n $cipher - $bits bits...
	CipherStrength $cipher $bits 1
    fi

    if (timeout 10s $ossl s_client $ssl -cipher $cipher -connect $SSLHOST < ~/sslthing.tmp 2>&1 | grep -E "^New.*Cipher is $cipher" > /dev/null); then
      if [ $2 ]; then
        echo OK
      else
 #       echo $cipher - $bits bits
	CipherStrength $cipher $bits 0
      fi
    else
      if [ $2 ]; then
        echo Failed
      fi
    fi
  done | grep -v error
done

## Remove temporary file
if [ -e ~/sslthing.tmp ]; then
	rm -f ~/sslthing.tmp
fi

