#!/bin/bash
ShowUsage() {
	echo "$0 <Mode:0=brute or 1=dict> <hash file>"
	echo "Note that if the hash file is a straight dump, only the hash needs to be extracted first."
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

hashFile=$2

if [ ! -e $hashFile ]; then
	echo "ERROR: Unable to find $hashFile"
	exit 2
fi

# 0 for brute, 1 for dictionary
BRUTEFORCE=$1

# cat $hashFile | cut -d: -f4 > hash.ntlm.txt

HASHCATEXE="hashcat"
USINGGPU=0

if [ -e /usr/bin/cudahashcat ]; then
	HASHCATEXE="cudahashcat"
	HASRENDERING=`glxinfo 2>/dev/null | grep -i "direct rendering" | wc -l`

	if [ $HASRENDERING -gt 0 ]; then
		echo "Found cudahashcat.... trying GPU-accelerated version."
		USINGGPU=1
	fi

else
	echo "Using CPU-based hashcat."
fi

if [ $BRUTEFORCE -eq 0 ]; then
	if [ $USINGGPU -eq 0 ]; then
		# Mask examples: a=all, l=lowercase, u=uppercase, d=number, s=special
		$HASHCATEXE -m 5600 -a 3 --pw-min=3 --pw-max=7  $hashFile ?uld
	else
		echo "WARNING: cudahashcat can only handle 1 hash at a time.  Using first hash from $hashfile..."
		GPUOPTION=""

		ISONWOPR=`hostname | grep "wopr" | wc -l`

		if [ $ISONWOPR -eq 1 ]; then
		# GPU 1 overheats, only use 2 and 3.
			GPUOPTION="--gpu-devices=2,3"
		fi

		$HASHCATEXE -m 5600 -a 3 -1 abcdefghijklmnopqrstuvwxyzSACMPBTDREGHKLFNVIOW0123456789\!.-_ `cat $hashFile | head -1`
	fi
else
# 	$HASHCATEXE -m 5600 -a 0 -r /usr/share/hashcat/rules/john.rule `head -1 $hashFile` /opt/wordlists/MikesList.wordlist.txt
	$HASHCATEXE -m 5600 -a 0 $hashFile /opt/wordlists/MikesList.wordlist.txt
fi

