#!/usr/bin/python
import itertools
import sys

# tokens = ["hel", "lo", "bye"]
tokens=sys.argv
del tokens[0]

if (len(tokens) == 0):
	print("Usage: crack.create_mangled_wordlist.sh <data1> <data2>....<data n>")
else:
	for i in range(1, len(tokens) + 1):
	    for p in itertools.permutations(tokens, i):
		print "".join(p)
