#!/bin/bash

if [ $# -lt 1 ]; then
	echo "Usage: $0 <cain file>"
	echo "Note: This may need to be manually constructed from the capture file.  Cain's cracker won't take the AES-256 type."
	echo "john 1.8-jumbo+ considers these hashes $krb5pa$18 so what you need to do is create a line entry that looks like:"
	echo ""
	echo "<domain>\<user>:\$krb5pa\$18\$\$\$\$<Hash from cain's 'K5.LST' (the capture file one not the cracker KRB5.LST one)"
	echo ""
	echo "To crack use: ./john --format:[krb5pa-sha1-opencl | krb5pa-sha1 | krb5pa-md5 | mskrb5] --wordlist=/opt/wordlists/MikesList.wordlist.txt --rules --fork=4  <password file>  to crack"
	echo ""
	echo "For GPU Accelerated: (based on 2 graphics cards):"
	echo "List devices with ./john --list=opencl-devices"
	echo "Look at how many computing cores it has then use that as the OMP_NUM_THREADS=<#>"
	echo ""
	echo "OMP_NUM_THREADS=13 ./john --fork=3 --dev=0,1,2 --format=krb5pa-sha1-opencl --wordlist=/opt/wordlists/MikesList.wordlist.txt --rules <file>"
	echo "OMP_NUM_THREADS=13 ./john --fork=3 --dev=0,1,2 --format=krb5pa-sha1-opencl --wordlist=/opt/wordlists/MikesList.wordlist.txt --rules=WordListMike <file>"
	echo ""
	echo "Doing this without the --rules will also speed things up.  There's also a --rules=WordListMike which uses fewer mangling rules."
#	echo "Tuning the LWS and GWS parameters can have a huge diff on performance.  The =0 settings above say to autotune and look in 256 block increments."
#	echo "You can test the algorithm with OMP_NUM_THREADS=8 LWS=0 GWS=0 STEP=256 ./john --dev=0,1 --format=krb5pa-sha1-opencl -t and see how it does."
	echo ""
	exit 0
fi

