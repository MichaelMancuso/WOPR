#!/bin/sh

if [ $# -lt 2 ]; then
	echo "Usage: $0 <host> <prefix>"
	echo ""
	echo "where:"
	echo "<host> is the file prefix 1.2.3.4 such as in 1.2.3.4.psk_key.txt"
	echo "<prefix> is the company designator (e.g. abc)"
	echo ""
	exit 1
fi

HOST=$1
PREFIX=$2

echo "-- Starting bulk crack at `date` ----"

crack.psk.sh --dictionary=/opt/wordlists/MikesList.wordlist.Plus1stCap.txt --psk-file=$HOST.psk_key.txt
crack.psk.sh --dictionary=MikesList.wordlist.Plus1stCap.txt.pre.$PREFIX.lower --psk-file=$HOST.psk_key.txt
crack.psk.sh --dictionary=MikesList.wordlist.Plus1stCap.txt.pre.$PREFIX.upper --psk-file=$HOST.psk_key.txt
crack.psk.sh --dictionary=MikesList.wordlist.Plus1stCap.txt.post.$PREFIX.lower --psk-file=$HOST.psk_key.txt
crack.psk.sh --dictionary=MikesList.wordlist.Plus1stCap.txt.post.$PREFIX.upper --psk-file=$HOST.psk_key.txt

echo "-- Completed bulk crack at `date` ----"

